/* -----------------------------------------------------------
   Aggregate the most frequently used Python “import/from … import”
   modules and R “library(…)” packages that appear in files whose
   names end with “.py” or “.r”.

   1.  SAMPLE_FILES gives the authoritative file path → use it to
       restrict the population to *.py / *.r files.
   2.  SAMPLE_CONTENTS holds the file text → use it to extract the
       package names with REGEXP_SUBSTR (flag ‘e’ returns the first
       capture group).
   3.  Produce two separate tallies (python / r), tag each row with
       a language label, UNION them, then sort within each language
       by descending frequency.
------------------------------------------------------------ */
WITH
/* -------- Python: plain “import …” ------------------------ */
py_import AS (
    SELECT
        LOWER(
            REGEXP_SUBSTR(
                c."content",
                '\\bimport\\s+([A-Za-z0-9_\\.]+)',   -- capture module name
                1, 1, 'e', 1)
        ) AS "package"
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
    JOIN  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f  USING ("id")
    WHERE f."path" ILIKE '%.py'
      AND c."content" ILIKE '%import %'
),
/* -------- Python: “from … import …” ----------------------- */
py_from AS (
    SELECT
        LOWER(
            REGEXP_SUBSTR(
                c."content",
                '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import',   -- capture module
                1, 1, 'e', 1)
        ) AS "package"
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
    JOIN  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f  USING ("id")
    WHERE f."path" ILIKE '%.py'
      AND c."content" ILIKE '%from %import%'
),
/* -------- R: “library(…)” -------------------------------- */
r_lib AS (
    SELECT
        LOWER(
            REGEXP_SUBSTR(
                c."content",
                'library\\(([^)]+)\\)',               -- capture library name
                1, 1, 'e', 1)
        ) AS "package"
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
    JOIN  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f  USING ("id")
    WHERE f."path" ILIKE '%.r'
      AND c."content" ILIKE '%library(%'
)
/* -------- Final aggregation & ordering ------------------- */
SELECT
    'python'                         AS "language",
    p."package",
    COUNT(*)                         AS "occurrence_cnt"
FROM (
        SELECT * FROM py_import
        UNION ALL
        SELECT * FROM py_from
) p
WHERE p."package" IS NOT NULL
GROUP BY 1, 2

UNION ALL

SELECT
    'r'                              AS "language",
    r."package",
    COUNT(*)                         AS "occurrence_cnt"
FROM r_lib r
WHERE r."package" IS NOT NULL
GROUP BY 1, 2

ORDER BY
    "language",
    "occurrence_cnt" DESC NULLS LAST;