WITH composer_files AS (
    SELECT
        PARSE_JSON("content") AS json_content
    FROM
        "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE
        LOWER("sample_path") LIKE '%composer.json'
        AND TRY_PARSE_JSON("content") IS NOT NULL
),
package_list AS (
    SELECT
        f.key AS package_name
    FROM
        composer_files cf,
        LATERAL FLATTEN(input => cf.json_content:"require") f
)
SELECT
    package_name,
    COUNT(*) AS frequency
FROM
    package_list
GROUP BY
    package_name
ORDER BY
    frequency DESC NULLS LAST,
    package_name;