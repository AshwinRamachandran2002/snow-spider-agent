WITH filtered AS (   -- keep only Python & R source files
    SELECT
        "sample_path",
        "content"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  LOWER("sample_path") LIKE '%.py'
       OR  LOWER("sample_path") LIKE '%.r'
),

/* ------------------------- PYTHON ------------------------- */
python_modules AS (
    SELECT
        'python' AS "language",
        REGEXP_SUBSTR(                          -- first module token
            TRIM(
                REGEXP_REPLACE(                 -- strip leading keywords
                    REGEXP_SUBSTR(
                        "content",
                        '^[[:space:]]*(import[^\\n\\r]*|from[^\\n\\r]*import[^\\n\\r]*)',
                        1, 1, 'im'
                    ),
                    '^[[:space:]]*(from|import)[[:space:]]+',
                    '',
                    1, 0, 'i'
                )
            ),
            '[A-Za-z0-9_\\.]+'
        ) AS "package_or_module"
    FROM  filtered
    WHERE LOWER("sample_path") LIKE '%.py'
),

/* --------------------------- R ---------------------------- */
r_packages AS (
    SELECT
        'r' AS "language",
        REGEXP_REPLACE(                         -- strip parentheses
            REGEXP_SUBSTR(
                REGEXP_SUBSTR(
                    "content",
                    'library\\s*\\([^)]*\\)',
                    1, 1, 'i'
                ),
                '\\([^)]*\\)'
            ),
            '^\\(|\\)$',
            ''
        ) AS "package_or_module"
    FROM  filtered
    WHERE LOWER("sample_path") LIKE '%.r'
),

/* ------------- UNION THE TWO LANGUAGES ------------------- */
all_pkgs AS (
    SELECT * FROM python_modules
    UNION ALL
    SELECT * FROM r_packages
)

/* --------------- FINAL AGGREGATION ----------------------- */
SELECT
    "language",
    "package_or_module",
    COUNT(*) AS "occurrences"
FROM   all_pkgs
WHERE  "package_or_module" IS NOT NULL
GROUP  BY "language", "package_or_module"
ORDER  BY "language", "occurrences" DESC NULLS LAST;