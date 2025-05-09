WITH import_blocks AS (
    /* pull the text that sits inside “import ( … )” */
    SELECT REGEXP_SUBSTR("content",
                         'import\\s*\\(([^)]*)\\)',
                         1, 1, 'e', 1)     AS "block"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "content" ILIKE '%import(%'
),
lines AS (
    /* break multi-line import blocks into one row per line */
    SELECT line.value::STRING AS "line"
    FROM   import_blocks,
           LATERAL FLATTEN(input => SPLIT("block", '\n')) line
),
packages AS (
    /* grab the package name that sits inside double quotes */
    SELECT REGEXP_SUBSTR("line",
                         '"([^"]+)"',
                         1, 1, 'e', 1)     AS "package"
    FROM   lines
)
SELECT  "package",
        COUNT(*)  AS "freq"
FROM     packages
WHERE    "package" IS NOT NULL
GROUP BY "package"
ORDER BY "freq" DESC NULLS LAST
LIMIT    10;