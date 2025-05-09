WITH latest_metadata AS (      -- keep only the newest release per package
    SELECT  LOWER("name")                               AS pkg_name,
            "home_page",
            "project_urls",
            ROW_NUMBER() OVER (PARTITION BY LOWER("name") 
                                ORDER BY "upload_time" DESC) AS rn
    FROM    PYPI.PYPI.DISTRIBUTION_METADATA
)
, newest AS (
    SELECT  pkg_name, "home_page", "project_urls"
    FROM    latest_metadata
    WHERE   rn = 1
)
, raw_urls AS (                -- collect every candidate URL
    /* home_page */
    SELECT  pkg_name, "home_page" AS url
    FROM    newest
    WHERE   "home_page" IS NOT NULL

    UNION ALL

    /* every value contained in project_urls variant */
    SELECT  pkg_name, value::string AS url
    FROM    newest,
            LATERAL FLATTEN ( input => "project_urls") f
    WHERE   value IS NOT NULL
)
, github_urls AS (             -- keep github links & clean them
    SELECT  pkg_name,
            REGEXP_REPLACE(
                url,
                '^https?://github\\.com/([^/]+)/([^/]+)(/.*)?',
                'https://github.com/\\1/\\2'
            ) AS repo_url
    FROM    raw_urls
    WHERE   url ILIKE '%github.com/%'
)
, repos_per_pkg AS (           -- distinct repo per package
    SELECT  DISTINCT pkg_name, repo_url
    FROM    github_urls
)
, dl_counts AS (               -- total download counts per package
    SELECT  LOWER("project")           AS pkg_name,
            COUNT(*)                   AS download_count
    FROM    PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY LOWER("project")
)
, ranked AS (                  -- rank by download count
    SELECT  d.pkg_name,
            d.download_count,
            r.repo_url,
            ROW_NUMBER() OVER (ORDER BY d.download_count DESC NULLS LAST) AS rn
    FROM    dl_counts d
    JOIN    repos_per_pkg r
      ON    d.pkg_name = r.pkg_name
)
SELECT  repo_url
FROM    ranked
WHERE   rn <= 3
ORDER BY rn;