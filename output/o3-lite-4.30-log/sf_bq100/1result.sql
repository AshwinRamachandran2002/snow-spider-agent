WITH import_blocks AS (
    SELECT
        REGEXP_SUBSTR("content", 'import \\([\\s\\S]*?\\)', 1, 1) AS "import_block"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE "binary" = FALSE
      AND "content" ILIKE '%import (%'
      AND REGEXP_SUBSTR("content", 'import \\([\\s\\S]*?\\)', 1, 1) IS NOT NULL
), lines AS (
    SELECT
        TRIM(f.value) AS "line"
    FROM import_blocks,
         LATERAL FLATTEN(input => SPLIT("import_block", '\n')) f
), packages AS (
    SELECT
        REPLACE(REGEXP_SUBSTR("line", '"[^"]+"', 1, 1), '"', '') AS "package_name"
    FROM lines
)
SELECT
    "package_name",
    COUNT(*) AS "frequency"
FROM packages
WHERE "package_name" IS NOT NULL
  AND "package_name" <> ''
GROUP BY "package_name"
ORDER BY "frequency" DESC NULLS LAST, "package_name"
LIMIT 10;