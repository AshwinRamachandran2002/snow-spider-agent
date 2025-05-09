WITH python_modules AS (
    SELECT
        LOWER(TRIM(s.value)) AS "MODULE"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL SPLIT_TO_TABLE(
             REGEXP_REPLACE(
                 REGEXP_REPLACE(
                     LOWER(c."content"),
                     'from\\s+([a-z0-9_\\.]+)\\s+import',
                     ',\\1,'
                 ),
                 'import\\s+([a-z0-9_\\.]+)',
                 ',\\1,'
             ),
             ','
         ) s
    WHERE LOWER(c."sample_path") LIKE '%.py'
      AND s.value IS NOT NULL
      AND s.value <> ''
      AND s.value RLIKE '^[a-z0-9_\\.]+$'
), r_modules AS (
    SELECT
        LOWER(TRIM(s.value)) AS "MODULE"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL SPLIT_TO_TABLE(
             REGEXP_REPLACE(
                 LOWER(c."content"),
                 'library\\s*\\(\\s*([a-z0-9_\\.]+)\\s*\\)',
                 ',\\1,'
             ),
             ','
         ) s
    WHERE LOWER(c."sample_path") LIKE '%.r'
      AND s.value IS NOT NULL
      AND s.value <> ''
      AND s.value RLIKE '^[a-z0-9_\\.]+$'
), all_modules AS (
    SELECT "MODULE" FROM python_modules
    UNION ALL
    SELECT "MODULE" FROM r_modules
)
SELECT
    "MODULE",
    COUNT(*) AS "FREQUENCY"
FROM all_modules
GROUP BY "MODULE"
ORDER BY "FREQUENCY" DESC NULLS LAST, "MODULE"
LIMIT 5;