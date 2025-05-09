SELECT
    f.KEY::STRING AS "PACKAGE_NAME",
    COUNT(*)      AS "FREQUENCY"
FROM (
    SELECT
        TRY_PARSE_JSON("content") AS json_doc
    FROM
        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE
        LOWER("sample_path") LIKE '%composer.json'
        AND "content" IS NOT NULL
        AND TRY_PARSE_JSON("content") IS NOT NULL
) AS c,
LATERAL FLATTEN(input => c.json_doc:"require") f
GROUP BY
    "PACKAGE_NAME"
ORDER BY
    "FREQUENCY" DESC NULLS LAST,
    "PACKAGE_NAME";