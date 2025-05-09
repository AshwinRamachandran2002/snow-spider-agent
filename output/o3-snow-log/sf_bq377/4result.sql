WITH json_files AS (
    SELECT
        "content"
    FROM
        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE
        LOWER("sample_path") LIKE '%composer.json'       -- PHP projects
        OR LOWER("sample_path") LIKE '%package.json'     -- Node.js projects
),
parsed AS (
    SELECT
        TRY_PARSE_JSON("content") AS j
    FROM
        json_files
    WHERE
        TRY_PARSE_JSON("content") IS NOT NULL            -- keep only valid JSON
),
required_pkgs AS (
    SELECT
        f.KEY::STRING AS package_name
    FROM
        parsed,
        LATERAL FLATTEN( INPUT => j:"require" ) AS f      -- extract "require" section
)
SELECT
    package_name,
    COUNT(*) AS frequency
FROM
    required_pkgs
GROUP BY
    package_name
ORDER BY
    frequency DESC NULLS LAST;