WITH import_blocks AS (
    SELECT
        "id",
        -- capture everything between "import (" and its closing ")"
        REGEXP_SUBSTR("content",
                      'import\\s*\\(([^)]*)\\)',
                      1,               -- start position
                      1,               -- first occurrence
                      's',             -- DOTALL so "." spans new‑lines
                      1)               -- return the first capture group
            AS "blk"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
),
import_lines AS (
    -- split multi‑line import blocks into individual lines
    SELECT
        "id",
        TRIM(value) AS "line"
    FROM import_blocks,
         LATERAL FLATTEN(INPUT => SPLIT("blk", '\n'))
    WHERE "blk" IS NOT NULL
),
packages AS (
    -- pick out the package name enclosed in double quotes
    SELECT
        REGEXP_SUBSTR("line",
                      '"([^"]+)"',
                      1, 1, 's', 1) AS "package"
    FROM import_lines
)
SELECT
    "package" AS "package_name",
    COUNT(*)  AS "frequency"
FROM packages
WHERE "package" IS NOT NULL
GROUP BY "package"
ORDER BY "frequency" DESC NULLS LAST, "package_name"
LIMIT 10;