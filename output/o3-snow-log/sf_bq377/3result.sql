WITH json_files AS (
    SELECT
        TRY_PARSE_JSON("content")         AS json_doc
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "binary" = FALSE
      AND "content" ILIKE '%"require"%'          -- only files mentioning a require section
      AND TRY_PARSE_JSON("content") IS NOT NULL  -- keep valid JSON documents
), require_pkgs AS (
    SELECT
        f.key::TEXT AS package_name
    FROM json_files,
         LATERAL FLATTEN(INPUT => json_doc:"require") f   -- iterate over keys in the require object
)
SELECT
    package_name,
    COUNT(*) AS frequency
FROM require_pkgs
GROUP BY package_name
ORDER BY frequency DESC NULLS LAST;