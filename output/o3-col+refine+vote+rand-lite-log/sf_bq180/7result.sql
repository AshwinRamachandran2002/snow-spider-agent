WITH python_modules AS (
    SELECT
        REGEXP_SUBSTR(
            line.value::STRING,
            '^(from|import)\\s+([A-Za-z0-9_\\.]+)',
            1, 1, 'e', 2
        ) AS "name"
    FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS" sc,
         LATERAL SPLIT_TO_TABLE(sc."content", '\n') line
    WHERE sc."sample_path" ILIKE '%.py'
),
r_packages AS (
    SELECT
        REGEXP_SUBSTR(
            line.value::STRING,
            'library\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
            1, 1, 'e', 1
        ) AS "name"
    FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS" sc,
         LATERAL SPLIT_TO_TABLE(sc."content", '\n') line
    WHERE sc."sample_path" ILIKE '%.r'
),
all_names AS (
    SELECT "name" FROM python_modules
    UNION ALL
    SELECT "name" FROM r_packages
)
SELECT
    "name" AS "module_or_package",
    COUNT(*) AS "total_occurrences"
FROM all_names
WHERE "name" IS NOT NULL
GROUP BY "name"
ORDER BY "total_occurrences" DESC NULLS LAST
LIMIT 5;