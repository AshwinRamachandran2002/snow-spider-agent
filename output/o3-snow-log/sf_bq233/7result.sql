WITH python_modules AS (
    SELECT
        REGEXP_SUBSTR(
            t.value,
            '(from|import)\\s+([A-Za-z0-9_.]+)',   /* capture group 2 = module */
            1, 1, 'e', 2
        ) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
          ON f."id" = c."id",
         LATERAL SPLIT_TO_TABLE(c."content", '\n') t
    WHERE LOWER(f."path") LIKE '%.py'
      AND (t.value ILIKE 'import %' OR t.value ILIKE 'from % import %')
),
r_libraries AS (
    SELECT
        REGEXP_SUBSTR(
            t.value,
            'library\\s*\\(\\s*([A-Za-z0-9_.]+)\\s*\\)',   /* capture group 1 = lib */
            1, 1, 'e', 1
        ) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') t
    WHERE LOWER(c."sample_path") LIKE '%.r'
      AND t.value ILIKE 'library(%'
)
SELECT
    'Python'         AS "language",
    module           AS "name",
    COUNT(*)         AS "occurrences"
FROM python_modules
WHERE module IS NOT NULL
GROUP BY module

UNION ALL

SELECT
    'R'              AS "language",
    module           AS "name",
    COUNT(*)         AS "occurrences"
FROM r_libraries
WHERE module IS NOT NULL
GROUP BY module

ORDER BY
    "language",
    "occurrences" DESC NULLS LAST;