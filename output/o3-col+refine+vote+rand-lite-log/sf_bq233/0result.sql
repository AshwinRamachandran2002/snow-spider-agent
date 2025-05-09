WITH python_imports AS (
    /* grab module names from “import …” */
    SELECT REGEXP_SUBSTR(line.value,
                         '\\bimport\\s+([A-Za-z0-9_\\.]+)',
                         1, 1, 'e', 1)   AS "module"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES      f
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS   c
           ON f."id" = c."id",
           LATERAL SPLIT_TO_TABLE(c."content", '\n')   line
    WHERE  LOWER(f."path") LIKE '%.py'
      AND  line.value ILIKE 'import %'

    UNION ALL

    /* …and from “from … import …” */
    SELECT REGEXP_SUBSTR(line.value,
                         '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import',
                         1, 1, 'e', 1)   AS "module"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES      f
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS   c
           ON f."id" = c."id",
           LATERAL SPLIT_TO_TABLE(c."content", '\n')   line
    WHERE  LOWER(f."path") LIKE '%.py'
      AND  line.value ILIKE 'from % import %'
),
r_imports AS (
    /* grab package names used in library(…) calls */
    SELECT REGEXP_SUBSTR(line.value,
                         'library\\s*\\(\\s*([A-Za-z0-9_\\.]+)\\s*\\)',
                         1, 1, 'e', 1)   AS "module"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS   c,
           LATERAL SPLIT_TO_TABLE(c."content", '\n')   line
    WHERE  LOWER(c."sample_path") LIKE '%.r'
      AND  line.value ILIKE 'library(%'
)

SELECT   "language",
         "module",
         COUNT(*) AS "occurrences"
FROM    (
           SELECT 'Python' AS "language", "module"
           FROM   python_imports
           WHERE  "module" IS NOT NULL AND "module" <> ''

           UNION ALL

           SELECT 'R'      AS "language", "module"
           FROM   r_imports
           WHERE  "module" IS NOT NULL AND "module" <> ''
        )
GROUP BY "language", "module"
ORDER BY "language", "occurrences" DESC NULLS LAST;