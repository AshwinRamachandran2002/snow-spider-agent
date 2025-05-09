/* Top-10 most frequently imported Java packages */
WITH imports AS (
    SELECT
        -- extract the package portion (everything up to the last identifier)
        REGEXP_SUBSTR(
            REGEXP_REPLACE(                             -- drop leading keywords
                REGEXP_REPLACE(ln.value::STRING,
                               '^import\\s+static\\s+', ''),
                '^import\\s+', ''
            ),
            '([A-Za-z0-9_\\.]+)\\.[A-Za-z0-9_\\*]+',    -- capture the package
            1, 1, 'e', 1
        )               AS "package_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
      ON f."id" = c."id",
    LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) ln
    WHERE f."path" ILIKE '%.java'                   -- only Java source files
      AND ln.value::STRING ILIKE 'import %'         -- keep import statements
)
SELECT
    "package_name",
    COUNT(*)        AS "import_count"
FROM imports
GROUP BY "package_name"
ORDER BY "import_count" DESC NULLS LAST
LIMIT 10;