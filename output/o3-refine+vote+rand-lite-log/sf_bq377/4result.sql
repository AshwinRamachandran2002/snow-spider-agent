WITH composer_files AS (
    SELECT
        PARSE_JSON("content") AS js
    FROM
        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE
        LOWER("sample_path") LIKE '%composer.json'     -- focus on composer.json files
        AND TRY_PARSE_JSON("content") IS NOT NULL      -- ensure valid JSON
        AND js:"require" IS NOT NULL                   -- must contain a "require" section
),
packages AS (
    SELECT
        pk.VALUE::STRING AS package_name
    FROM
        composer_files,
        LATERAL FLATTEN(INPUT => OBJECT_KEYS(js:"require")) pk  -- extract each package key
)
SELECT
    package_name,
    COUNT(*) AS package_frequency
FROM
    packages
GROUP BY
    package_name
ORDER BY
    package_frequency DESC NULLS LAST,
    package_name;