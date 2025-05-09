WITH imports AS (   -- grab the first multi‑line “import (…)” block found in each file
    SELECT REGEXP_SUBSTR("content", 'import \\([^)]+\\)', 1, 1, 'e') AS "import_block"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "content" ILIKE '%import (%'
),
lines AS (          -- break the block into individual lines
    SELECT TRIM(t.value) AS "import_line"
    FROM   imports,
           LATERAL SPLIT_TO_TABLE(
               REGEXP_REPLACE("import_block", '^import \\(|\\)$', ''),  -- drop the surrounding “import ( … )”
               '\n'
           ) AS t
),
packages AS (       -- pull out the text inside double quotes
    SELECT REGEXP_SUBSTR("import_line", '"([^"]+)"', 1, 1, 'e', 1) AS "package"
    FROM   lines
    WHERE  "import_line" ILIKE '%"%'
)
SELECT   "package",
         COUNT(*) AS "usage_count"
FROM     packages
WHERE    "package" IS NOT NULL
GROUP BY "package"
ORDER BY "usage_count" DESC NULLS LAST
LIMIT 10;