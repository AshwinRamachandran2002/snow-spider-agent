WITH latest_meta AS (      -- newest release per package
    SELECT *
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY "upload_time" DESC) = 1
),
github_urls AS (           -- grab & clean GitHub URLs
    SELECT
        m."name",
        REGEXP_SUBSTR(f.value::string,
                      'https?://github\\.com/[^/]+/[^/]+') AS clean_url
    FROM latest_meta m,
         LATERAL FLATTEN(input => m."project_urls") f
    WHERE REGEXP_SUBSTR(f.value::string,
                        'https?://github\\.com/[^/]+/[^/]+') IS NOT NULL
),
downloads AS (             -- total downloads per package
    SELECT
        LOWER("project") AS name,
        COUNT(*)         AS download_count
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY LOWER("project")
),
combined AS (              -- join metadata with download counts
    SELECT
        g.clean_url,
        d.download_count
    FROM github_urls g
    JOIN downloads  d
      ON LOWER(g."name") = d.name
),
ranked AS (                -- one row per repo with its download total
    SELECT
        clean_url,
        MAX(download_count) AS download_count
    FROM combined
    GROUP BY clean_url
)
SELECT clean_url
FROM ranked
ORDER BY download_count DESC NULLS LAST
LIMIT 3;