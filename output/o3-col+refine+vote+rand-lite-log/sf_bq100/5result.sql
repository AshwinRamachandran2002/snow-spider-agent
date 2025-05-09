WITH import_lines AS (
    SELECT
        f.value::STRING AS "import_line"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS sc,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                 REGEXP_SUBSTR(sc."content",
                               'import[[:space:]]*\\([^)]*\\)',   -- grab multi-line import block
                               1, 1, 'e'),
                 '\n')
         ) AS f
    WHERE sc."content" ILIKE '%import (%'          -- only files that contain multi-line imports
),
packages AS (
    SELECT
        TRIM(REGEXP_REPLACE("import_line",
                            '[^A-Za-z0-9_./-]',   -- strip quotes and other punctuation
                            ''))       AS "package_name"
    FROM import_lines
    WHERE "import_line" ILIKE '%"%'                -- keep lines that actually quote a package
)
SELECT
    "package_name",
    COUNT(*) AS "freq"
FROM packages
WHERE "package_name" IS NOT NULL
  AND "package_name" <> ''                         -- ignore empty results
GROUP BY "package_name"
ORDER BY "freq" DESC NULLS LAST                   -- most frequent first
LIMIT 10;