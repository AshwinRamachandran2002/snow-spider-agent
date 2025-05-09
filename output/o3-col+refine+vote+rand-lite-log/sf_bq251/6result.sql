WITH latest AS (          -- newest version of every package
    SELECT
        "name"                                           AS pkg,
        "home_page"                                      AS "home_page",
        "project_urls"                                   AS "project_urls",
        ROW_NUMBER() OVER (PARTITION BY "name"
                           ORDER BY "upload_time" DESC)  AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
),
latest_only AS (          -- keep only newest row per package
    SELECT pkg, "home_page", "project_urls"
    FROM   latest
    WHERE  rn = 1
),
-- GitHub URLs in the home_page column
home_urls AS (
    SELECT
        pkg,
        REGEXP_SUBSTR("home_page",
                      'https?://github\.com/[^/]+/[^/]+') AS repo_url
    FROM   latest_only
    WHERE  "home_page" ILIKE '%github.com%'
),
-- GitHub URLs found inside project_urls JSON
proj_urls AS (
    SELECT
        l.pkg,
        REGEXP_SUBSTR(v.value::STRING,
                      'https?://github\.com/[^/]+/[^/]+') AS repo_url
    FROM   latest_only l,
           LATERAL FLATTEN(INPUT => PARSE_JSON(l."project_urls")) v
    WHERE  v.value::STRING ILIKE '%github.com%'
),
-- combine sources & keep distinct repo URLs
github_repos AS (
    SELECT DISTINCT pkg, repo_url
    FROM (
        SELECT * FROM home_urls
        UNION ALL
        SELECT * FROM proj_urls
    )
    WHERE repo_url IS NOT NULL
),
-- total download counts per package
downloads AS (
    SELECT
        "project"                    AS pkg,
        COUNT(*)                     AS download_cnt
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
-- join repos with download counts
joined AS (
    SELECT
        g.pkg,
        g.repo_url,
        d.download_cnt,
        ROW_NUMBER() OVER (PARTITION BY g.pkg ORDER BY g.repo_url) AS repo_rank
    FROM github_repos g
    JOIN downloads   d ON d.pkg = g.pkg
)
-- final output: GitHub URLs for the top-3 downloaded packages
SELECT repo_url
FROM   joined
WHERE  repo_rank = 1            -- one repo URL per package
ORDER  BY download_cnt DESC NULLS LAST
LIMIT 3;