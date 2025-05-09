WITH lines AS (
    SELECT
        c."sample_path"         AS "sample_path",
        f.VALUE::STRING         AS "line"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') f
    WHERE c."sample_path" ILIKE '%.py'
       OR c."sample_path" ILIKE '%.r'
),
python_from AS (
    SELECT
        LOWER(
            SPLIT_PART(
                REGEXP_SUBSTR(
                    "line",
                    '\\bfrom\\s+([A-Za-z_][A-Za-z0-9_.]+)\\s+import',
                    1, 1, 'ie', 1
                ),
                '.', 1
            )
        ) AS "module"
    FROM lines
    WHERE "sample_path" ILIKE '%.py'
),
python_import AS (
    SELECT
        LOWER(
            SPLIT_PART(
                REGEXP_SUBSTR(
                    "line",
                    '\\bimport\\s+([A-Za-z_][A-Za-z0-9_]+)',
                    1, 1, 'ie', 1
                ),
                '.', 1
            )
        ) AS "module"
    FROM lines
    WHERE "sample_path" ILIKE '%.py'
),
r_library AS (
    SELECT
        LOWER(
            REGEXP_SUBSTR(
                "line",
                '\\blibrary\\s*\\(\\s*([A-Za-z0-9_.]+)\\s*\\)',
                1, 1, 'ie', 1
            )
        ) AS "module"
    FROM lines
    WHERE "sample_path" ILIKE '%.r'
),
all_modules AS (
    SELECT "module" FROM python_from
    UNION ALL
    SELECT "module" FROM python_import
    UNION ALL
    SELECT "module" FROM r_library
)
SELECT
    "module",
    COUNT(*) AS "usage_count"
FROM all_modules
WHERE "module" IS NOT NULL
  AND "module" <> ''
GROUP BY "module"
ORDER BY "usage_count" DESC NULLS LAST, "module"
LIMIT 5;