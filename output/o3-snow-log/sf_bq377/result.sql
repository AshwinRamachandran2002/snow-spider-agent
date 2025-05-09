WITH json_files AS (
    SELECT
        TRY_PARSE_JSON("content") AS j
    FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS"
),
parsed AS (
    SELECT
        j
    FROM json_files
    WHERE j IS NOT NULL
      AND j:"require" IS NOT NULL                -- keep only JSON having "require"
),
requirements AS (
    SELECT
        f.key AS package_name
    FROM parsed,
         LATERAL FLATTEN(input => j:"require") f  -- iterate over "require" object
)
SELECT
    package_name,
    COUNT(*) AS package_count
FROM requirements
GROUP BY package_name
ORDER BY package_count DESC NULLS LAST;