/* -------------------------------------------------
   Count imported Python modules and R libraries
   ------------------------------------------------- */
WITH filtered_files AS (      -- keep only .py and .r sources
    SELECT  sf."repo_name",
            sf."path",
            sc."content",
            CASE
                WHEN sf."path" ILIKE '%.py' THEN 'Python'
                WHEN sf."path" ILIKE '%.r'  THEN 'R'
            END                               AS "language"
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    sf
    JOIN    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
           ON sf."id" = sc."id"
    WHERE   sf."path" ILIKE '%.py'
        OR  sf."path" ILIKE '%.r'
),
lines AS (                     -- split each source file into lines
    SELECT  f."language",
            TRIM(s.VALUE) AS "line"
    FROM    filtered_files f,
            LATERAL SPLIT_TO_TABLE(f."content", '\n') s   -- s.VALUE = each line
),
extracted AS (                 -- extract python modules or R libraries
    SELECT  "language",
            /* Python:  import xxx   |   from xxx import yyy  -> capture group 2 */
            REGEXP_SUBSTR(
                "line",
                '^[[:space:]]*(from|import)[[:space:]]+([A-Za-z0-9_\\.]+)',
                1,          -- position
                1,          -- first occurrence
                'i',        -- case-insensitive
                2           -- return 2nd capture group (module name)
            )  AS "python_mod",
            /* R: library(xxx)  -> capture group 1 */
            REGEXP_SUBSTR(
                "line",
                '^[[:space:]]*library[[:space:]]*\\([[:space:]]*([A-Za-z0-9_\\.]+)',
                1,
                1,
                'i',
                1           -- module name
            )  AS "r_lib"
    FROM    lines
)
SELECT  "language",
        COALESCE("python_mod", "r_lib")  AS "package",
        COUNT(*)                         AS "occurrences"
FROM    extracted
WHERE  ( "language" = 'Python' AND "python_mod" IS NOT NULL )
   OR  ( "language" = 'R'      AND "r_lib"     IS NOT NULL )
GROUP BY "language", "package"
ORDER BY "language",
         "occurrences" DESC NULLS LAST;