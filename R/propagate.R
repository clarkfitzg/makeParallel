# Propagate Resources
#
# This is pretty cool- it resembles R's evaluator.
# Attaching the information to the nodes of the AST allows us to query the state at any point in the evaluation, versus seeing what happened after everything runs.


# Thu Jun 13 08:55:57 PDT 2019
#
# This is a proof of concept to determine if the code calls `by`, where the argument to split the data on is known.
#
# The approach is to first propagate through the special semantic meanings of the code that we care about.
# It works by iterating over the code, method dispatch on the class of the nodes, and updating mutable data structures as it infers things.
# rstatic made it all much easier than it would have been otherwise.
#
# Many nodes may refer to the same resource.
# There are three data structures involved:
#
# - ast The propagation step assigns each node a resource ID.
# - name_resource is an environment where the keys are variable names in the code and the values are resource ID's.
# - resources is an environment where the keys are resource ID's and the values are a list containing the state that we care about, such as chunked = TRUE or FALSE.


# Sat Aug 31 15:34:24 PDT 2019
#
# Originally I set this up to make it easy to go from variable names to resources.
# Now I would like to got the other way- I have the resources, and I want to know if it was assigned locally.
# I can add such a field to the resources list.

# Hmmm. There's potentially a many to many relationship between resources and name_resource.
# That is, many names could refer to the same resource, and the same name could refer to many resources.
# This makes things a little tricky.

# In scheduleDataParallel.R
# I directly add the external data resource:
#    resources[[data_id]] = list(chunked = TRUE, varName = data@varName)
#
# There should be a clearer model for this, for example, all the values in the resource environment have a class inheriting from Resource.
# Alternatively, I could nix the resource object completely and instead build off the AST, with another data structure only for resources that don't correspond to elements of the AST.
# There are two ways to implement such a data structure: I could just use the `.data` field in the AST, or build another tree with identical structure as the AST, that just holds the resources I'm interested in.

# All implementation details though- end user should never see this.
# Or should they?
# I can imagine building the task graph like this.


# Modifies the node and resources.
# Returns the name of the added resource
new_named_resource = function(node, resources, namer, chunked = FALSE, ...) 
{
    new_name = namer()
    r = list(chunked = chunked, ...)

    # All based on side effects
    assign(new_name, value = r, pos = resources)
    resource_id(node) = new_name

    new_name
}


# Propagate resource identifiers through an ast
#
# Must be called from the root of the AST, which is probably a Brace
#
# @param ast rstatic language object
# @param name_resource environment mapping symbol names to resource identifiers.
#       Think of this as the evaluation environment of the code.
# @param resources environment mapping resource identifiers to the actual resource descriptions
# @ value list containing updated ast and resource.
#       ast is the original ast except that the nodes \code{x.data$resource_id} have values to look up the resources
#       resources is the orginal resource plus any new distributed resources
propagate = function(node, name_resource, resources, namer, ...)
{
    # To simulate evaluation we need to walk up from the leaf nodes of the tree.
    # This is different from the conventional DFS / BFS.
    # We can implement this by making sure all the children have their resource_id's set
    for(child in rstatic::children(node)){
        # Walk everything except user defined functions.
        if(is(child, "Function")){
            update_resource(child, name_resource, resources, namer, ...)
        } else {
            Recall(child, name_resource, resources, namer, ...)
        }
    }
    # This guarantees the children all have resources, so we can proceed to this node.
    update_resource(node, name_resource, resources, namer, ...)
}


update_resource = function(node, name_resource, resources, namer, ...) UseMethod("update_resource")


update_resource.Subset = function(node, name_resource, resources, namer, ...)
{
    if(node$fn$value == "["
       && resources[[resource_id(node$args[[1]])]]$chunked
       && is(node$args[[2]], "EmptyArgument")
       && is(node$args[[3]], "Character")
    ){
        new_named_resource(node, resources, namer,
            chunked = TRUE, column_subset = TRUE, column_names = node$args[[3]]$value)
    } else {
        NextMethod()
    }
}


update_resource.Symbol = function(node, name_resource, resources, namer, ...)
{
    nm = node$value 
    if(nm %in% names(name_resource)){
        resource_id(node) = name_resource[[nm]]
    } else {
        NextMethod()
    }
}


update_resource.default = function(node, name_resource, resources, namer, ...)
{
    new_named_resource(node, resources, namer)
}


update_resource.Assign = function(node, name_resource, resources, namer, ...)
{
    r_id = resource_id(node$read) 

    # This will write over an existing value for that symbol, which is what we want.
    resource_id(node$write) = r_id
    resource_id(node) = r_id
    name_resource[[node$write$value]] = r_id

    resources[[r_id]][["assigned"]] = TRUE
    resources[[r_id]][["varName"]] = node$write$ssa_name
}


# Dirty hack because of issues with match_call and primitives.
# Modification *must* happen in place or we lose the resources associated with the nodes.
clean_up_split_call = function(s)
{
    split_params = c("x", "f")
    split_args = names(s$args$contents)
    if(is.null(split_args)){
        names(s$args$contents) = split_params
    } else if(any(split_args != split_params)){
        stop("Unexpected form of split call: ", rstatic::as_language(s))
    }
}


update_resource.Call = function(node, name_resource, resources, namer
        , chunkFuncs = character(), reduceFuncs = character(), ...)
{
    # First implementation will behave naively.
    # If the call is to a vectorized function, and any of the arguments to that function are chunked objects, then the result is a chunked object.
    # A more robust version will match on argument names, but for this we will need the argument list to be named.

    fname = node$fn$value

    chunkableArgs = sapply(node$args$contents, isChunked, resources = resources)
    # TODO: Check for and handle mixing chunked and non chunked objects?
    hasChunkArgs = any(chunkableArgs)

    # TODO:
    # This treats split() as a special case.
    # Do we want to create an extensible mechanism for users to specify the behavior of other special functions?
    # Then it becomes pretty similar to function handlers in CodeDepends.
    # This one is an implementation using the rstatic AST rather than R's AST.
    # We'll need to carefully explain the resources for users to be able to extend it.


    if(fname == "split" && hasChunkArgs){

        clean_up_split_call(node)

        IDsplit_x = resource_id(node$args$contents[["x"]])
        IDsplit_f = resource_id(node$args$contents[["f"]])

        if(is.null(IDsplit_x) || is.null(IDsplit_f))
            stop("Cannot find resources in split call.")

        # Adding these resource IDs in here as values means that resources refers to itself.
        # It's getting to be a fairly complicated self referential data structure.

        return(new_named_resource(node, resources, namer
            , split = TRUE
            , chunked = hasChunkArgs
            , IDsplit_x = IDsplit_x
            , IDsplit_f = IDsplit_f
            ))
    }

    if(fname %in% chunkFuncs && hasChunkArgs){

        # TODO: This is a hack to propagate the uniqueValueBound forward.
        # It won't be correct if the arguments are not both chunked in the same way.
        # We need a more general mechanism.
        first_chunk_arg = node$args$contents[chunkableArgs][[1L]]
        uvb = get_resource(first_chunk_arg, resources)[["uniqueValueBound"]]

        new_named_resource(node, resources, namer, chunked = TRUE, uniqueValueBound = uvb)
    } else if(fname %in% reduceFuncs && hasChunkArgs){
        new_named_resource(node, resources, namer, reduceFun = fname)
    } else {
        NextMethod()
    }
}


namer_factory = function(basename = "r"){
    cnt = rstatic::Counter$new()
    function() rstatic::next_name(cnt, basename)
}


resource_id = function(node) node[[".data"]][["resource_id"]]


`resource_id<-` = function(node, value){
    node[[".data"]][["resource_id"]] = value
    node
}


# The resource that corresponds to a node, or NULL if none exists
get_resource = function(node, resources)
{
    id = resource_id(node)
    if(is.null(id)) NULL else resources[[id]]
}


# Check if the resource associated with a node is chunked or not
isChunked = function(node, resources)
{
    r = get_resource(node, resources)
    if(is.null(r)) FALSE else r$chunked
}


# Check if the resource associated with a node has been locally assigned, and is not chunked
isLocalNotChunked = function(node, resources)
{
    r = get_resource(node, resources)
    if(is.null(r))
        return(FALSE)
    !is.null(r$assigned) && r$assigned && !r$chunked 
}


# TODO: split followed by lapply is more general, so maybe I should probably be working with that?

# Returns the name of the column that the call splits by if it can find it, and FALSE otherwise
splits_by_known_column = function(bycall, resources)
{
    # bycall a call to `by`
    # resources descriptions that act like an evaluation environment for the call to `by`
    
    # Check that:
    # 1. data_arg is a large chunked data object
    # 2. index_arg is a known column

    # For now I'm not thinking about whether the chunking schemes match up or if they inherit from the same object.

    data_arg = get_resource(bycall$args$contents[[1]], resources)
    index_arg = get_resource(bycall$args$contents[[2]], resources)

    if(!data_arg[["chunked"]]){
        return(FALSE)
    }

    cs = index_arg[["column_subset"]]
    if(!is.null(cs) && cs){
        index_arg[["column_names"]]
    } else {
        FALSE
    }
}

