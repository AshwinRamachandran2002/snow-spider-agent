WITH import_blocks AS (
    /* 1. keep only files that contain an “import (…)” block and pull
          the text that sits inside the first pair of parentheses        */
    SELECT
        REGEXP_SUBSTR("content",
                      'import\\s*\\(([^)]*)\\)',      -- everything between ( … )
                      1, 1, 'e', 1)     AS block
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "content" ILIKE '%import (%'
), import_lines AS (
    /* 2. split the multiline block into individual lines                */
    SELECT
        TRIM(f.value::text) AS line
    FROM import_blocks,
         LATERAL FLATTEN(input => SPLIT(block, '\n')) f
), packages AS (
    /* 3. pull the package name that is written inside the first "…"      */
    SELECT
        REGEXP_SUBSTR(line,
                      '"([^"]+)"',      -- text inside double quotes
                      1, 1, 'e', 1) AS package
    FROM import_lines
)
SELECT
    REPLACE(package, '"', '')          AS package_name,
    COUNT(*)                           AS frequency
FROM packages
WHERE package IS NOT NULL
GROUP BY package_name
ORDER BY frequency DESC NULLS LAST, package_name
LIMIT 10;