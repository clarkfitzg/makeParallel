sql_template = readLines(
    system.file("templates/udaf.sql", package = "autoparallel")
)

R_template = readLines(
    system.file("templates/udaf.R", package = "autoparallel")
)



#' Writes User Defined Aggregation Function
#'
#' Generates R and SQL scripts to call as user defined aggregation
#' functions in Hive
#'
#' This approach splits the data based on the value of the column
#' \code{cluster_by}. Each group of split data must be small enough to fit
#' in memory of the R process that runs it.
#'
#' This function is relatively low level. It provides the foundation for
#' something more advanced that knows and uses the schema of the database.
#' Defaults were chosen to do the least destructive things possible, so
#' they don't overwrite existing files and data.
#'
#'
#' Feedback: 
#'
#' Do I attempt to have consistency with similar funcs /
#' packages? Ie. DBI package uses statement, lapply uses FUN
#'
#' Alternatively I could use caps to denote SQL things, ie. CLUSTER_BY
#'
#' Looking back at this now 
#'
#'
#' @param f function which accepts a grouped data frame and returns a
#'  data frame
#' @param cluster_by character name of column to \code{CLUSTER BY}, ie.
#' split the main table based on this column and apply \code{f} to each
#' group
#' @param input_table character name of table to be transformed, ie.
#'  \code{SELECT input_cols FROM input_table}. Can also contain more SQL,
#'  such as \code{input_table WHERE col1 < 10}.
#' @param input_cols input column names. See \code{col.names} in
#'  \code{\link[utils]{read.table}}.
#' @param input_classes character vector of classes for columns. See
#'  \code{colClasses} in \code{\link[utils]{read.table}}.
#' @param output_table character name of table to \code{INSERT INTO
#'  output_table}
#' @param output_cols character vector of columns that f will output
#' @param rows_per_chunk integer number of rows to process in each chunk.
#'  If this is too small, say 10, then the generated script will be slow.
#'  If this is too large, say 1 billion, then the R process may fail
#'  because it uses excessive memory.
#' @param base_name character base name of script to write ie. foo.R and foo.sql
#' @param include_script character name of an R script to include in the
#'  generated script. This may contain supporting functions, for example.
#' @param overwrite_script logical write over any existing scripts with
#'  \code{base_name}?
#' @param overwrite_table first call \code{DROP TABLE output_table}, and
#'  then \code{CREATE TABLE output_table} with appropriate column types?
#' @param sep character field separator string
#' @param verbose logical log messages to \code{stderr} so that they can be
#'  examined later via \code{$ yarn logs -applicationId <your app id>
#'  -log_files stderr}
#' @param try logical If \code{try = TRUE} then the script will attempt to call
#' \code{f} on every group, and ignore those groups that fail. If \code{try
#' = FALSE} then a failure on any group will cause the whole Hive job to
#' fail.
#' @param tmptable character name of temporary table in SQL query
#' @return scripts character vector containing generated scripts
#' @examples
#' #write_udaf_scripts(...)
#' @export
write_udaf_scripts = function(f
    , cluster_by
    , input_table
    , input_cols
    , input_classes
    , output_table
    , output_cols
    , output_classes
    , base_name = "udaf"
    , include_script = NULL
    , overwrite_script = FALSE
    , overwrite_table = FALSE
    , rows_per_chunk = 1e6L
    , sep = "'\\t'"             # sep is a little tricky
    , verbose = FALSE
    , try = FALSE
    , tmptable = "tmp"
){

    #if(!overwrite_script && any(file.exists(
    udaf_dot_sql = paste0(base_name, ".sql")
    udaf_dot_R = paste0(base_name, ".R")
    gen_time = Sys.time()
    version = sessionInfo()$otherPkgs$autoparallel$Version
    output_table_definition = make_output_table_def(output_cols, output_classes)
    
    # Pulls variables from parent environment
    sqlcode = whisker::whisker.render(sql_template)

    if(!is.null(include_script)){
        include_script = paste0(readLines(include_script), collapse = "\n")
    }

    # This just drops R code into an R script using mustache templating. An
    # alternative way is to save all these objects into a binary file and
    # send that file to the workers.
    Rcode = whisker::whisker.render(R_template, data = list(include_script = include_script
        , verbose = verbose
        , rows_per_chunk = rows_per_chunk
        , cluster_by = deparse(cluster_by)
        , sep = sep
        , input_cols = deparse(input_cols)
        , input_classes = deparse(input_classes)
        , try = try
        , f = paste0(capture.output(print.function(f)), collapse = "\n")
        , gen_time = gen_time
        , version = version
    ))

    writeLines(sqlcode, udaf_dot_sql)
    writeLines(Rcode, udaf_dot_R)

    list(sql = sqlcode, R = Rcode)
}


R_to_Hive = c(logical = "BOOLEAN", integer = "INT", numeric = "DOUBLE")


make_output_table_def = function(output_cols, output_classes)
{

    x = paste(output_cols, R_to_Hive[output_classes])
    ddl = whisker::iteratelist(x, value = "ddl")
    ddl[[1]]$first = TRUE
    ddl

}


#' Write Program To File
write_program = function(program, file)
{
    sink(file)
    for(expr in program){
        print(expr)
    }
    sink()
}


