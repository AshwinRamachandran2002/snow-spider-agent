WITH raw_lines AS (
    SELECT
        REGEXP_SUBSTR(l."VALUE", '"[^"]+"') AS quoted_pkg
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') AS l
    WHERE c."content" ILIKE '%import (%'      -- only blobs with multi-line import blocks
      AND l."VALUE" ILIKE '%"%"%'             -- keep lines that still contain quotes
),
packages AS (                                  -- strip the surrounding quotes
    SELECT REPLACE(quoted_pkg, '"', '') AS package
    FROM raw_lines
    WHERE quoted_pkg IS NOT NULL
)
SELECT
    package,
    COUNT(*) AS freq
FROM packages
GROUP BY package
ORDER BY freq DESC NULLS LAST
LIMIT 10;