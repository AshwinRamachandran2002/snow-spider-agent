WITH composer_files AS (
    SELECT "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE TRY_PARSE_JSON("content"):"require" IS NOT NULL
), 
packages AS (
    SELECT
        fl.key::STRING AS "package_name"
    FROM composer_files,
         LATERAL FLATTEN(INPUT => TRY_PARSE_JSON("content"):"require") fl
)
SELECT
    "package_name",
    COUNT(*) AS "frequency"
FROM packages
GROUP BY "package_name"
ORDER BY "frequency" DESC NULLS LAST;