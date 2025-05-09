SELECT package_name, COUNT(*) AS "Count"
FROM (
    SELECT
        REGEXP_SUBSTR(content_line.value, '^import(\\s+static)?\\s+([a-zA-Z0-9_\\.]+)', 1, 1, 'c', 2) AS package_name
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS",
        LATERAL FLATTEN(input => SPLIT("content", '\n')) AS content_line
    WHERE "binary" = FALSE AND "sample_path" LIKE '%.java'
        AND content_line.value LIKE 'import %'
) AS imports
WHERE package_name IS NOT NULL
GROUP BY package_name
ORDER BY "Count" DESC NULLS LAST
LIMIT 10;