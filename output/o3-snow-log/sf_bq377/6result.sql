WITH json_files AS (
    SELECT
        "sample_repo_name",
        "sample_path",
        TRY_PARSE_JSON("content")  AS json_data
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%composer.json'
      AND TRY_PARSE_JSON("content"):require IS NOT NULL
),
packages AS (
    SELECT
        LOWER(TRIM(r.key::string)) AS package_name
    FROM json_files,
         LATERAL FLATTEN(input => json_data:require) r
)
SELECT
    package_name,
    COUNT(*) AS freq
FROM packages
GROUP BY package_name
ORDER BY freq DESC NULLS LAST;