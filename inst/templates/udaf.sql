-- {{{gen_time}}}
-- Automatically generated from R by autoparallel version {{{autoparallel_version}}}

add FILE {{{udaf_dot_R}}}
;

{{{#overwrite_table}}}
DROP TABLE {{{output_table}}} 
;

CREATE TABLE {{{output_table}}} (
  {{{#output_table_definition}}}{{{^first}}}  , {{{/first}}}{{{ddl}}}
{{{/output_table_definition}}})
ROW FORMAT DELIMITED
FIELDS TERMINATED BY {{{sep}}}
;

INSERT OVERWRITE TABLE {{{output_table}}} {{{/overwrite_table}}}
SELECT
TRANSFORM ({{{input_cols}}})
USING "Rscript {{{udaf_dot_R}}}"
AS (
    {{{output_cols}}}
)
FROM (
    SELECT {{{input_cols}}}
    FROM {{{input_table}}}
    CLUSTER BY {{{cluster_by}}}
) AS {{{tmptable}}}
;
