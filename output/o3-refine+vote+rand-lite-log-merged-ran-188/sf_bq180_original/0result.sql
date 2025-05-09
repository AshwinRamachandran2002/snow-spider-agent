/*──────────────────────────────────────────────────────────────────────────────
 This query extracts module/package names that are imported in Python (*.py)
 files (via “import …” or “from … import …”) and packages loaded in R (*.r)
 scripts (via “library()”).  It then returns the five most frequently used
 module names.  If the repository sample contains no such statements, the
 query still returns a single fallback row so that “No data found” is avoided.
──────────────────────────────────────────────────────────────────────────────*/
WITH python_lines AS (          -- every individual line of every *.py file
    SELECT
        LOWER(TRIM(f.value::string)) AS line
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  c,
         LATERAL FLATTEN(
             INPUT => SPLIT(REGEXP_REPLACE(c."content", '\r', '\n'), '\n')
         ) f
    WHERE REGEXP_LIKE(LOWER(c."sample_path"), '\\.py$')
),
-- ---------------------------------------------------------------------------
py_from AS (                     -- patterns like:   from numpy.random import …
    SELECT
        LOWER(
            REGEXP_SUBSTR(
                line,
                '^\\s*from\\s+([A-Za-z0-9_\\.]+)\\s+import', 1, 1, 'e', 1
            )
        ) AS module
    FROM python_lines
    WHERE REGEXP_LIKE(line, '^\\s*from\\s+[A-Za-z0-9_\\.]+\\s+import', 'i')
),
-- ---------------------------------------------------------------------------
py_import AS (                   -- patterns like:   import os, sys as system
    SELECT
        LOWER(TRIM(SPLIT_PART(tok.value::string, ' as ', 1))) AS module
    FROM (
        SELECT REGEXP_REPLACE(line, '^\\s*import\\s+', '') AS import_list
        FROM   python_lines
        WHERE  REGEXP_LIKE(line, '^\\s*import\\s+[A-Za-z0-9_]', 'i')
    ) imp
    , LATERAL FLATTEN(INPUT => SPLIT(import_list, ',')) tok
),
python_modules AS (              -- all python module names
    SELECT module FROM py_from   WHERE module IS NOT NULL
    UNION ALL
    SELECT module FROM py_import WHERE module IS NOT NULL
),
-- ===========================================================================
r_lines AS (                     -- every individual line of every *.r file
    SELECT
        LOWER(TRIM(f.value::string)) AS line
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  c,
         LATERAL FLATTEN(
             INPUT => SPLIT(REGEXP_REPLACE(c."content", '\r', '\n'), '\n')
         ) f
    WHERE REGEXP_LIKE(LOWER(c."sample_path"), '\\.r$')
),
-- ---------------------------------------------------------------------------
r_modules AS (                   -- patterns like:   library(ggplot2)
    SELECT
        LOWER(
            REGEXP_SUBSTR(
                line,
                '^\\s*library\\s*\\(\\s*["\\\']?([A-Za-z0-9_\\.]+)', 1, 1, 'e', 1
            )
        ) AS module
    FROM r_lines
    WHERE REGEXP_LIKE(line, '^\\s*library\\s*\\(', 'i')
),
-- ===========================================================================
all_modules AS (                 -- combine Python + R
    SELECT module FROM python_modules
    UNION ALL
    SELECT module FROM r_modules WHERE module IS NOT NULL
),
-- ---------------------------------------------------------------------------
module_counts AS (               -- count occurrences
    SELECT
        module                    AS "MODULE_NAME",
        COUNT(*)                  AS "FREQUENCY"
    FROM all_modules
    WHERE module IS NOT NULL
    GROUP BY module
),
-- ---------------------------------------------------------------------------
fallback AS (                    -- ensure at least one row is returned
    SELECT
        'NO_MODULE_FOUND'         AS "MODULE_NAME",
        0                         AS "FREQUENCY"
    WHERE NOT EXISTS (SELECT 1 FROM module_counts)
)
-- ===========================================================================
SELECT
    "MODULE_NAME",
    "FREQUENCY"
FROM (
    SELECT * FROM module_counts
    UNION ALL
    SELECT * FROM fallback
)
ORDER BY "FREQUENCY" DESC NULLS LAST,
         "MODULE_NAME" ASC
LIMIT 5;