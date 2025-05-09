WITH content_with_import AS (                       -- only files that have “import (”
    SELECT
        "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE POSITION('import (' IN "content") > 0
),
lines AS (                                           -- split those files into lines
    SELECT
        TRIM(f.value)::STRING AS "line"
    FROM content_with_import,
         LATERAL FLATTEN( INPUT => SPLIT("content", '\n') ) f
),
packages AS (                                        -- extract quoted package names
    SELECT
        REGEXP_SUBSTR(
            "line",
            '"([^"]+)"',            -- capture the text between double quotes
            1,                      -- start position
            1,                      -- occurrence
            'e',                    -- use extended syntax so () forms a group
            1                       -- return the first (and only) capture group
        ) AS "package"
    FROM lines
    WHERE REGEXP_LIKE(                               -- line looks like:  "pkg"   or  alias "pkg"
        "line",
        '^\\s*(import[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*[[:space:]]+)?\"[^"]+\"'
    )
)
SELECT
    "package",
    COUNT(*) AS "package_count"
FROM packages
WHERE "package" IS NOT NULL
GROUP BY "package"
ORDER BY "package_count" DESC NULLS LAST, "package" ASC
LIMIT 10;