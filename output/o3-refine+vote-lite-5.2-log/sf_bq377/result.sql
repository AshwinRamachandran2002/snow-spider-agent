WITH json_sources AS (
    SELECT
        TRY_PARSE_JSON("content") AS content_json
    FROM
        "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE
        "content" ILIKE '%"require"%'
        AND TRY_PARSE_JSON("content") IS NOT NULL
),
packages AS (
    SELECT
        f."KEY"::STRING AS package_name
    FROM
        json_sources,
        LATERAL FLATTEN(input => content_json:"require") f
)
SELECT
    package_name,
    COUNT(*) AS frequency
FROM
    packages
GROUP BY
    package_name
ORDER BY
    frequency DESC NULLS LAST,
    package_name;