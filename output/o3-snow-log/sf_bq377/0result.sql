WITH composer_files AS (  -- 1. keep only composer.json files that are text
    SELECT
        "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "binary" = FALSE
      AND LOWER("sample_path") LIKE '%composer.json'
), parsed_json AS (        -- 2. parse the JSON; discard rows that are not valid JSON
    SELECT
        TRY_PARSE_JSON("content") AS j
    FROM composer_files
    WHERE TRY_PARSE_JSON("content") IS NOT NULL
), require_packages AS (   -- 3. get every key inside the "require" object
    SELECT
        f.key::string AS package
    FROM parsed_json,
         LATERAL FLATTEN(INPUT => j:"require") f
)
SELECT
    package,
    COUNT(*) AS freq
FROM require_packages
GROUP BY package
ORDER BY freq DESC NULLS LAST;