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
# - resources is an environment where the keys are resource ID's and the values are a list containing the state that we care about, such as chunked_object = TRUE or FALSE.


# Sat Aug 31 15:34:24 PDT 2019
#
# Originally I set this up to make it easy to go from variable names to resources.
# Now I would like to got the other way- I have the resources, and I want to know if it was assigned locally.
# I can add such a field to the resources list.


# Modifies the node and resources.
# Returns the name of the added resource
new_named_resource = function(node, resources, namer, chunked_object = FALSE, ...) 
{
    new_name = namer()
    r = list(chunked_object = chunked_object, ...)

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
        Recall(child, name_resource, resources, namer, ...)
    }
    # This guarantees the children all have resources, so we can proceed to this node.
    update_resource(node, name_resource, resources, namer, ...)
}


update_resource = function(node, name_resource, resources, namer, ...) UseMethod("update_resource")


update_resource.Subset = function(node, name_resource, resources, namer, ...)
{
    if(node$fn$value == "["
       && resources[[resource_id(node$args[[1]])]]$chunked_object
       && is(node$args[[2]], "EmptyArgument")
       && is(node$args[[3]], "Character")
    ){
        new_named_resource(node, resources, namer,
            chunked_object = TRUE, column_subset = TRUE, column_names = node$args[[3]]$value)
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
}


update_resource.Call = function(node, name_resource, resources, namer, chunkableFuncs = character(), ...)
{
    # First implementation will behave naively.
    # If the call is to a vectorized function, and any of the arguments to that function are chunked objects, then the result is a chunked object.
    # A more robust version will match on argument names, but for this we will need the argument list to be named.

    fname = node$fn$value
    chunkableArgs = sapply(node$args$contents, isChunked, resources = resources)

    # TODO:
    # This treats split() as a special case.
    # Do we want to create an extensible mechanism for users to specify the behavior of other special functions?
    # Then it becomes pretty similar to function handlers in CodeDepends.
    # This one is an implementation using the rstatic AST rather than R's AST.
    # We'll need to carefully explain the resources for users to be able to extend it.

    if(fname == "split"){

        # Call matching needs to happen in a preprocessing step, because it's useful in many places.
        # Assume that it has happened here.
        #split_call = rstatic::match_call(node, split)

        resourceToSplit = get_resource(node$args$contents$x, resources)
        splitFactor = get_resource(node$args$contents$f, resources)

        # TODO: Check for and handle mixing chunked and non chunked objects?

        return(new_named_resource(node, resources, namer
            , split = TRUE
            , resourceToSplit = resourceToSplit
            , splitFactor = splitFactor
            ))
    }


    if(fname %in% chunkableFuncs && any(chunkableArgs)){
        new_named_resource(node, resources, namer, chunked_object = TRUE)
    } else {
        NextMethod()
    }
}


namer_factory = function(basename = "r"){
    cnt = rstatic::Counter$new()
    function() rstatic::next_name(cnt, basename)
}


resource_id = function(node) node$.data[["resource_id"]]


`resource_id<-` = function(node, value){
    node$.data[["resource_id"]] = value
    node
}


# The resource that corresponds to a node, or NULL if none exists
get_resource = function(node, resources)
{
    resources[[resource_id(node)]]
}


# Check if the resource associated with a node is chunked or not
isChunked = function(node, resources) get_resource(node, resources)$chunked_object


# Check if the resource associated with a node has been locally assigned, and is not chunked
isLocalNotChunked = function(node, resources)
{
    r = get_resource(node, resources)
    !is.null(r$assigned) && r$assigned && !r$chunked_object 
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

    if(!data_arg[["chunked_object"]]){
        return(FALSE)
    }

    cs = index_arg[["column_subset"]]
    if(!is.null(cs) && cs){
        index_arg[["column_names"]]
    } else {
        FALSE
    }
}

