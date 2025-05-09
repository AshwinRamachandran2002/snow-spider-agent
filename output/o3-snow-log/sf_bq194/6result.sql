/* 1) pick all python / R / Rmd / ipynb files                               */
WITH relevant_files AS (     
    SELECT sf."id"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES sf
    WHERE  LOWER(sf."path") LIKE '%.py'
       OR  LOWER(sf."path") LIKE '%.r'
       OR  LOWER(sf."path") LIKE '%.rmd'
       OR  LOWER(sf."path") LIKE '%.ipynb'            -- treat notebooks as text
),
/* 2) split each file’s contents into individual lines                      */
file_lines AS (
    SELECT 
        fl.value::STRING AS line
    FROM   relevant_files rf
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
           ON sc."id" = rf."id",
           LATERAL FLATTEN ( INPUT => SPLIT(sc."content", '\n') ) fl
),
/* 3) extract imported / loaded module-names from those lines               */
imports AS (
    SELECT
        /* python:  import foo   |  from foo.bar import … */
        COALESCE(
            REGEXP_SUBSTR(line ,
                           '^\\s*(from|import)\\s+([A-Za-z0-9_\\.]+)',
                           1 , 1 , 'e' , 2),
            /* R:  library(foo)   |  require("foo.bar")   */
            REGEXP_SUBSTR(line ,
                           '^\\s*(library|require)\\(\\s*[\'"]?([A-Za-z0-9_\\.]+)',
                           1 , 1 , 'e' , 2)
        ) AS module_name
    FROM file_lines
),
/* 4) count how many times each module / library appears                    */
mod_counts AS (
    SELECT module_name ,
           COUNT(*) AS import_count
    FROM   imports
    WHERE  module_name IS NOT NULL
    GROUP  BY module_name
)
/* 5) return the 2nd most-frequently imported / loaded module               */
SELECT module_name ,
       import_count
FROM   mod_counts
ORDER  BY import_count DESC NULLS LAST ,
          module_name                    -- deterministic tie-breaker
LIMIT 1 OFFSET 1;                         -- second place