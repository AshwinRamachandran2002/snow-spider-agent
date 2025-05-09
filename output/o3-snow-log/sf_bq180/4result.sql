WITH modules AS (
    /* Python: `import module` */
    SELECT
        LOWER(
            REGEXP_SUBSTR(lines.value,
                          '^\\s*import\\s+([A-Za-z0-9_\\.]+)',
                          1, 1, 'ie', 1)
        ) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') AS lines
    WHERE LOWER(c."sample_path") LIKE '%.py'
      AND lines.value ILIKE 'import %'
      AND REGEXP_SUBSTR(lines.value,
                        '^\\s*import\\s+([A-Za-z0-9_\\.]+)',
                        1, 1, 'ie', 1) IS NOT NULL

    UNION ALL

    /* Python: `from module import …` */
    SELECT
        LOWER(
            REGEXP_SUBSTR(lines.value,
                          '^\\s*from\\s+([A-Za-z0-9_\\.]+)\\s+import',
                          1, 1, 'ie', 1)
        ) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') AS lines
    WHERE LOWER(c."sample_path") LIKE '%.py'
      AND lines.value ILIKE 'from % import %'
      AND REGEXP_SUBSTR(lines.value,
                        '^\\s*from\\s+([A-Za-z0-9_\\.]+)\\s+import',
                        1, 1, 'ie', 1) IS NOT NULL

    UNION ALL

    /* R: library(module) */
    SELECT
        LOWER(
            REGEXP_SUBSTR(lines.value,
                          '^.*library\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                          1, 1, 'ie', 1)
        ) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') AS lines
    WHERE LOWER(c."sample_path") LIKE '%.r'
      AND lines.value ILIKE '%library(%'
      AND REGEXP_SUBSTR(lines.value,
                        '^.*library\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                        1, 1, 'ie', 1) IS NOT NULL
)

SELECT
    module AS "module_name",
    COUNT(*) AS "frequency"
FROM modules
GROUP BY module
ORDER BY "frequency" DESC NULLS LAST
LIMIT 5;