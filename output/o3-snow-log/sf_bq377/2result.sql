WITH json_files AS (
    -- keep only files that look like JSON and contain a "require" section
    SELECT
        parse_json("content"):"require"  AS require_obj
    FROM
        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE
        -- fast pre-filter, cuts down parsing cost
        "content" ILIKE '%"require"%'
        AND "sample_path" ILIKE '%.json'
), require_pairs AS (
    -- explode the "require" object to get one row per package name
    SELECT
        LOWER(f.KEY)::STRING  AS package_name
    FROM
        json_files,
        LATERAL FLATTEN(INPUT => require_obj) f
)
SELECT
    package_name,
    COUNT(*) AS frequency
FROM
    require_pairs
GROUP BY
    package_name
ORDER BY
    frequency DESC NULLS LAST;