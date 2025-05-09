WITH candidate_files AS (
    SELECT
        TRY_PARSE_JSON("content") AS json_body
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "content" ILIKE '%"require"%'
),
require_packages AS (
    SELECT
        f.value::STRING AS package_name
    FROM candidate_files c,
         LATERAL FLATTEN(INPUT => OBJECT_KEYS(c.json_body:"require")) f
    WHERE c.json_body:"require" IS NOT NULL
)
SELECT
    package_name,
    COUNT(*) AS frequency
FROM require_packages
GROUP BY package_name
ORDER BY frequency DESC NULLS LAST, package_name;