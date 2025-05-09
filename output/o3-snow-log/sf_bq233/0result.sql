/* 1.  Pull only *.py and *.r files, join with their contents            */
WITH filtered_files AS (
    SELECT  f."path",
            f."id",
            c."content"
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     AS f
    JOIN    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  AS c
           ON f."id" = c."id"
    WHERE   LOWER(f."path") LIKE '%.py'
        OR  LOWER(f."path") LIKE '%.r'
),

/* 2.  Split every file into single lines and tag the language           */
lines AS (
    SELECT  ff."path",
            CASE WHEN LOWER(ff."path") LIKE '%.py' THEN 'Python'
                 ELSE 'R'
            END                       AS "language",
            line.value                AS "line_text"
    FROM    filtered_files  ff,
            LATERAL SPLIT_TO_TABLE(ff."content", '\n') AS line
),

/* 3a. Extract Python modules appearing after “import …”                 */
py_import AS (
    SELECT  'Python' AS "language",
            REGEXP_SUBSTR("line_text",
                          '\\bimport\\s+([A-Za-z0-9_\\.]+)', 1, 1, 'e') AS "module"
    FROM    lines
    WHERE   "language" = 'Python'
      AND   "line_text" ILIKE 'import %'
),

/* 3b. Extract Python modules appearing after “from … import …”           */
py_from_import AS (
    SELECT  'Python' AS "language",
            REGEXP_SUBSTR("line_text",
                          '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import', 1, 1, 'e') AS "module"
    FROM    lines
    WHERE   "language" = 'Python'
      AND   "line_text" ILIKE 'from %import%'
),

/* 3c. Extract R libraries used in library(...) calls                     */
r_libraries AS (
    SELECT  'R' AS "language",
            REGEXP_SUBSTR("line_text",
                          'library\\(([^)]+)\\)', 1, 1, 'e')            AS "module"
    FROM    lines
    WHERE   "language" = 'R'
      AND   "line_text" ILIKE '%library(%'
),

/* 4.  Union all extracted names                                          */
all_modules AS (
    SELECT * FROM py_import      WHERE "module" IS NOT NULL
    UNION ALL
    SELECT * FROM py_from_import WHERE "module" IS NOT NULL
    UNION ALL
    SELECT * FROM r_libraries    WHERE "module" IS NOT NULL
)

/* 5.  Final aggregation and ordering                                     */
SELECT   "language",
         "module"      AS "module_or_library",
         COUNT(*)      AS "occurrences"
FROM     all_modules
GROUP BY "language", "module"
ORDER BY "language" ASC,
         "occurrences" DESC NULLS LAST;