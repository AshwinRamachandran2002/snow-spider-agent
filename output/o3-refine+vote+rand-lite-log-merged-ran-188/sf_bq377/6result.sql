WITH "COMPOSER_FILES" AS (
    SELECT
        PARSE_JSON("content")  AS "JSON_DOC"
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%composer.json'          -- keep only composer.json files
)
SELECT 
    f.KEY                               AS "PACKAGE_NAME",
    COUNT(*)                            AS "FREQUENCY"
FROM "COMPOSER_FILES",
     LATERAL FLATTEN(input => "JSON_DOC":require) f    -- expand keys under "require"
GROUP BY 
    f.KEY
ORDER BY 
    "FREQUENCY" DESC NULLS LAST,
    "PACKAGE_NAME";