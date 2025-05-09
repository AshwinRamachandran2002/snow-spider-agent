WITH latest_metadata AS (               -- newest release for every package
    SELECT *
    FROM (
        SELECT  d.*,
                ROW_NUMBER() OVER (PARTITION BY "name"
                                    ORDER BY "upload_time" DESC) AS rn
        FROM    PYPI.PYPI.DISTRIBUTION_METADATA d
    )
    WHERE rn = 1
),
download_counts AS (                    -- total file-download counts
    SELECT  "project" AS "name",
            COUNT(*)  AS download_count
    FROM    PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
github_urls AS (                        -- extract & clean GitHub URLs
    SELECT  lm."name",
            dc.download_count,
            REGEXP_REPLACE(
                REGEXP_SUBSTR(
                    f.value::STRING,
                    'https://github\\.com/[^ )"\\'']+'
                ),
                '/issues.*|/pull.*|/blob.*|/tree.*$',
                ''
            ) AS repo_url
    FROM    latest_metadata lm
    JOIN    download_counts dc
           ON lm."name" = dc."name",
           LATERAL FLATTEN(INPUT => PARSE_JSON(lm."project_urls")) f
    WHERE   f.value::STRING ILIKE '%github.com%'
),
dedup AS (                              -- one cleaned URL per project
    SELECT  "name",
            repo_url,
            download_count,
            ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY repo_url) AS rn
    FROM    github_urls
    WHERE   repo_url IS NOT NULL
)
SELECT  repo_url
FROM    dedup
WHERE   rn = 1                          -- first URL for each project
ORDER BY download_count DESC NULLS LAST
LIMIT 3;