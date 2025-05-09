WITH json_files AS (
    /* keep only JSON-style manifest files that usually contain a “require” section */
    SELECT  "content"
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE   LOWER("sample_path") LIKE '%composer.json'      -- PHP / Composer
        OR  LOWER("sample_path") LIKE '%package.json'       -- Node.js / npm
        OR  LOWER("sample_path") LIKE '%.json'              -- any other *.json file
),
parsed AS (
    /* safely convert the text blob to VARIANT (NULL if not valid JSON) */
    SELECT  TRY_PARSE_JSON("content")  AS j
    FROM    json_files
    WHERE   TRY_PARSE_JSON("content") IS NOT NULL
),
requires AS (
    /* keep rows that actually have a “require” object */
    SELECT  j:"require"  AS req
    FROM    parsed
    WHERE   j:"require" IS NOT NULL
),
package_keys AS (
    /* extract the keys (package names) from each “require” object */
    SELECT  VALUE::string   AS package
    FROM    requires,
            LATERAL FLATTEN( INPUT => OBJECT_KEYS(req) )
)
SELECT  package,
        COUNT(*) AS frequency
FROM    package_keys
GROUP BY package
ORDER BY frequency DESC NULLS LAST;