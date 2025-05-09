WITH import_blocks AS (     -- 1. isolate the whole  “import (…)” block
    SELECT
        "id",
        REGEXP_SUBSTR(
            "content",
            'import\\s*\\(([^)]*)\\)',   -- capture text between the parentheses
            1, 1, 'e', 1                 -- return the first parenthesised group
        ) AS "import_block"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "content" ILIKE '%import (%'
),

import_lines AS (           -- 2. split multi-line blocks into individual lines
    SELECT
        ib."id",
        TRIM(f.value) AS "import_line"
    FROM import_blocks ib,
         LATERAL FLATTEN(input => SPLIT(ib."import_block", '\n')) f
),

packages AS (               -- 3. extract the package path inside double quotes
    SELECT
        REGEXP_SUBSTR(
            "import_line",
            '"([^"]+)"',    -- text inside the first pair of quotes
            1, 1, 'e', 1
        ) AS "package"
    FROM import_lines
)

-- 4. count occurrences and list the 10 most-imported packages
SELECT
    REGEXP_REPLACE("package", '^"|"$', '') AS "package_name",
    COUNT(*)                                AS "times_imported"
FROM packages
WHERE "package" IS NOT NULL                -- ignore non-matches
GROUP BY "package_name"
ORDER BY "times_imported" DESC NULLS LAST
LIMIT 10;