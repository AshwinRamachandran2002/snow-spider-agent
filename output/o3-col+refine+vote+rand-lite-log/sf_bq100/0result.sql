WITH import_blocks AS (           -- 1. grab first multi-line import (…) block from every file
    SELECT REGEXP_SUBSTR("content",
                         'import \\([\\s\\S]*?\\)',
                         1, 1, 'm')      AS "blk"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "content" ILIKE '%import (%'
),
lines AS (                        -- 2. split each captured block into individual lines
    SELECT TRIM(t.value) AS "line"
    FROM   import_blocks,
           LATERAL SPLIT_TO_TABLE("blk", '\n') t
),
pkgs AS (                         -- 3. pull out quoted package names and strip the quotes
    SELECT REPLACE(REGEXP_SUBSTR("line", '"[^"]+"'), '"', '') AS "pkg"
    FROM   lines
    WHERE  REGEXP_SUBSTR("line", '"[^"]+"') IS NOT NULL
)
SELECT
    "pkg"      AS "package",
    COUNT(*)   AS "freq"
FROM   pkgs
WHERE  "pkg" IS NOT NULL
GROUP  BY "pkg"
ORDER  BY "freq" DESC NULLS LAST
LIMIT  10;