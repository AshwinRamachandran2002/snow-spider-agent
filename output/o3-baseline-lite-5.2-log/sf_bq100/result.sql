WITH files_with_imports AS (
    -- keep only files that contain a parenthesised import statement
    SELECT
        REGEXP_SUBSTR("content", 'import\\s*\\(([^)]*?)\\)', 1, 1, 'e') AS block
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "content" ILIKE '%import (%'
),
lines AS (
    -- split the import block into individual (newline‑separated) lines
    SELECT
        TRIM(value) AS line
    FROM files_with_imports,
         LATERAL FLATTEN(input => SPLIT(block, '\n'))
),
packages AS (
    -- extract the package path that is enclosed in double‑quotes
    SELECT
        REGEXP_SUBSTR(line, '"([^"]+)"', 1, 1, 'e') AS pkg
    FROM lines
)
SELECT
    pkg                           AS package,
    COUNT(*)                      AS freq
FROM packages
WHERE pkg IS NOT NULL
GROUP BY pkg
ORDER BY freq DESC NULLS LAST, package
LIMIT 10;