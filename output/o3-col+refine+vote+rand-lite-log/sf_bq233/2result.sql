WITH python_modules AS (
    SELECT
        'python'                                                  AS "language",
        REGEXP_REPLACE(
            l.value::STRING,
            '^\\s*(from|import)\\s+([A-Za-z0-9_\\.]+).*',
            '\\2'
        )                                                         AS "name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
      ON f."id" = c."id",
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) l
    WHERE f."path" ILIKE '%.py'
      AND (l.value::STRING ILIKE 'import %'
           OR l.value::STRING ILIKE 'from % import %')
),
r_packages AS (
    SELECT
        'r'                                                       AS "language",
        REGEXP_REPLACE(
            l.value::STRING,
            '.*library\\s*\\(\\s*([A-Za-z0-9_\\.]+)\\s*\\).*',
            '\\1'
        )                                                         AS "name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c,
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) l
    WHERE (c."sample_path" ILIKE '%.r' OR c."sample_path" ILIKE '%.R')
      AND l.value::STRING ILIKE '%library(%'
),
all_counts AS (
    SELECT * FROM python_modules
    UNION ALL
    SELECT * FROM r_packages
)
SELECT
    "language",
    "name",
    COUNT(*) AS "occurrences"
FROM all_counts
GROUP BY "language", "name"
ORDER BY "language", "occurrences" DESC NULLS LAST;