WITH latest_meta AS (                                                            -- most-recent release per package
    SELECT *
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY "upload_time" DESC) = 1
),
downloads AS (                                                                   -- total file-download count
    SELECT "project", COUNT(*) AS download_cnt
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
meta_dl AS (                                                                     -- keep only packages having downloads
    SELECT m."name",
           d.download_cnt,
           m."project_urls"
    FROM latest_meta m
    JOIN downloads d
      ON LOWER(m."name") = LOWER(d."project")
),
github_raw AS (                                                                  -- explode urls and keep github ones
    SELECT
        md."name",
        md.download_cnt,
        REGEXP_REPLACE(                                                          -- clean URL
            TRIM(SPLIT_PART(f.value::STRING, ',', -1)),
            '/(issues|pull|blob|tree)(/.*)?$',
            ''
        ) AS github_url
    FROM meta_dl md,
         LATERAL FLATTEN(input => md."project_urls") f
    WHERE f.value::STRING ILIKE '%github%'
),
github_dedup AS (                                                                -- unique repo urls with max downloads
    SELECT
        github_url,
        MAX(download_cnt) AS download_cnt
    FROM github_raw
    GROUP BY github_url
)
SELECT github_url
FROM github_dedup
ORDER BY download_cnt DESC NULLS LAST
LIMIT 3;