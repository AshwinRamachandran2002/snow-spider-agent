WITH matched_files AS (   /* keep only *.py and *.r files */
    SELECT "id",
           "path"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
    WHERE  LOWER("path") LIKE '%.py'
       OR  LOWER("path") LIKE '%.r'
),
file_contents AS (        /* bring in file bodies */
    SELECT mf."path",
           mf."id",
           sc."content"
    FROM   matched_files mf
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
           ON sc."id" = mf."id"
),
lines AS (                /* split each file into separate lines */
    SELECT CASE 
               WHEN LOWER(fc."path") LIKE '%.py' THEN 'Python'
               ELSE 'R'
           END                                AS "language",
           TRIM(l.value::STRING)              AS "line"
    FROM   file_contents fc,
           LATERAL FLATTEN( INPUT => SPLIT(fc."content", '\n') ) l
),
modules AS (              /* extract module / library names */
    SELECT  "language",
            CASE
                 /* Python: import xxx */
                 WHEN "language" = 'Python'
                      AND REGEXP_LIKE("line",
                                      '^\\s*import\\s+[A-Za-z0-9_\\.]+') THEN
                      REGEXP_SUBSTR("line",
                                    'import\\s+([A-Za-z0-9_\\.]+)',
                                    1, 1, 'e', 1)

                 /* Python: from xxx import yyy */
                 WHEN "language" = 'Python'
                      AND REGEXP_LIKE("line",
                                      '^\\s*from\\s+[A-Za-z0-9_\\.]+\\s+import') THEN
                      REGEXP_SUBSTR("line",
                                    'from\\s+([A-Za-z0-9_\\.]+)\\s+import',
                                    1, 1, 'e', 1)

                 /* R: library(xxx) or library("xxx") */
                 WHEN "language" = 'R'
                      AND REGEXP_LIKE("line", '\\blibrary\\(') THEN
                      REGEXP_REPLACE(
                          REGEXP_SUBSTR("line",
                                        'library\\(\\s*([A-Za-z0-9_\\.\"\']+)\\s*\\)',
                                        1, 1, 'e', 1),
                          '[\\s"]', '')      /* strip spaces & double quotes */
            END AS "module"
    FROM   lines
)
SELECT   "language",
         "module",
         COUNT(*) AS "occurrences"
FROM     modules
WHERE    "module" IS NOT NULL
GROUP BY "language", "module"
ORDER BY "language",
         "occurrences" DESC NULLS LAST,
         "module";