WITH blocks AS (      -- isolate the whole “import ( … )” block
    SELECT  REGEXP_SUBSTR("content",
                          'import\\s*\\([\\s\\S]*?\\)',
                          1, 1, 'm')           AS "imports_block"
    FROM    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE   "content" ILIKE '%import (%'
),
lines AS (             -- split the block into individual lines
    SELECT  TRIM(f.value)                     AS "import_line"
    FROM    blocks,
            LATERAL FLATTEN(INPUT => SPLIT("imports_block", '\n')) f
),
packages AS (          -- grab package names that are inside double-quotes
    SELECT  REGEXP_SUBSTR("import_line",
                          '"([^"]+)"',
                          1, 1, 'e', 1)       AS "package"
    FROM    lines
    WHERE   "import_line" ILIKE '%"%'         -- contains quotes
      AND   "import_line" NOT ILIKE 'import (%'-- skip header
      AND   TRIM("import_line") <> ')'        -- skip footer
)
SELECT  "package",
        COUNT(*) AS "usage_count"
FROM    packages
WHERE   "package" IS NOT NULL
GROUP BY "package"
ORDER BY "usage_count" DESC NULLS LAST
LIMIT 10;