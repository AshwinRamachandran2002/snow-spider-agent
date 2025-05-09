SELECT
    "package_name",
    COUNT(*) AS "ImportCount"
FROM (
    SELECT
        REGEXP_SUBSTR(
            line.value::STRING,
            '^import[[:space:]]+(static[[:space:]]+)?([a-zA-Z_][a-zA-Z0-9_.$]*)',
            1,
            1,
            'i',
            2
        ) AS "package_name"
    FROM
        "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS",
        LATERAL FLATTEN(
            input => SPLIT("content", '\n')
        ) line
    WHERE
        "sample_path" LIKE '%.java'
        AND "binary" = FALSE
        AND line.value ILIKE 'import %'
) AS imports
WHERE
    "package_name" IS NOT NULL
GROUP BY
    "package_name"
ORDER BY
    "ImportCount" DESC NULLS LAST
LIMIT 10;