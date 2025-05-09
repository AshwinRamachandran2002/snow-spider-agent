WITH
/* ---------- Python import/fro​m-import lines ---------- */
python_lines AS (
    SELECT
        LOWER(
            COALESCE(
                /* plain  import xxx[,yyy]…   -> capture first name */
                REGEXP_SUBSTR(line.value ,
                              '^\\s*import\\s+([A-Za-z0-9_\\.]+)',
                              1 , 1 , 'i' , 1 ),
                /* from xxx import yyy…       -> capture module before  import */
                REGEXP_SUBSTR(line.value ,
                              '^\\s*from\\s+([A-Za-z0-9_\\.]+)\\s+import',
                              1 , 1 , 'i' , 1 )
            )
        )                 AS module
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
          ON c."id" = f."id"
         ,LATERAL SPLIT_TO_TABLE(c."content", '\n')  line
    WHERE LOWER(f."path") LIKE '%.py'
      AND (
            REGEXP_LIKE(line.value , '^\\s*import\\s+[A-Za-z0-9_\\.]+', 'i')
         OR REGEXP_LIKE(line.value , '^\\s*from\\s+[A-Za-z0-9_\\.]+\\s+import', 'i')
      )
      AND module IS NOT NULL
),
/* ---------- R  library(…) calls ---------- */
r_lines AS (
    SELECT
        LOWER(
            TRIM(
                REGEXP_SUBSTR(line.value ,
                              'library\\s*\\(\\s*([^,\\)]+)',
                              1 , 1 , 'i' , 1 )
            )
        )                 AS package
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
          ON c."id" = f."id"
         ,LATERAL SPLIT_TO_TABLE(c."content", '\n')  line
    WHERE LOWER(f."path") LIKE '%.r'
      AND REGEXP_LIKE(line.value , 'library\\s*\\(', 'i')
      AND package IS NOT NULL
)
/* ---------- Aggregate & present ---------- */
SELECT
    'python'                        AS "language",
    module                          AS "name",
    COUNT(*)                        AS "occurrences"
FROM   python_lines
GROUP  BY module

UNION ALL

SELECT
    'r'                             AS "language",
    package                         AS "name",
    COUNT(*)                        AS "occurrences"
FROM   r_lines
GROUP  BY package

ORDER BY
    "language",
    "occurrences" DESC NULLS LAST;