WITH latest_dist AS (          -- newest release per package
    SELECT
        LOWER("name") AS name_lower,
        COALESCE(CAST("project_urls" AS STRING), '') || ' ' || COALESCE("home_page", '') AS url_blob,
        ROW_NUMBER() OVER (PARTITION BY LOWER("name") ORDER BY "upload_time" DESC) AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
),

dist_urls AS (                 -- extract first GitHub URL
    SELECT
        name_lower,
        REGEXP_SUBSTR(url_blob, 'https?://github\\.com/[^\\s,"]+') AS raw_url
    FROM latest_dist
    WHERE rn = 1
),

clean_urls AS (                -- clean URL
    SELECT
        name_lower,
        REGEXP_REPLACE(                       -- remove unwanted sub-paths then trailing slash
            REGEXP_REPLACE(raw_url, '/(issues|pull|blob|tree)(/.*)?$', ''),
            '/$',''
        ) AS github_url
    FROM dist_urls
    WHERE raw_url IS NOT NULL
),

download_counts AS (           -- total downloads per project
    SELECT
        LOWER("project") AS project_lower,
        COUNT(*) AS download_count
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY LOWER("project")
),

ranked AS (                    -- combine & rank
    SELECT
        cu.github_url,
        dc.download_count
    FROM clean_urls cu
    JOIN download_counts dc
      ON cu.name_lower = dc.project_lower
    WHERE cu.github_url IS NOT NULL
)

SELECT github_url
FROM ranked
ORDER BY download_count DESC NULLS LAST
LIMIT 3;