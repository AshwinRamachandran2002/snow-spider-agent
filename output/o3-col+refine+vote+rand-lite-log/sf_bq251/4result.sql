WITH download_counts AS (   -- total downloads per package
    SELECT 
        "project",
        COUNT(*) AS download_count
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
latest_metadata AS (       -- keep only newest release for each package
    SELECT dm.*
    FROM PYPI.PYPI.DISTRIBUTION_METADATA dm
    JOIN (
        SELECT 
            "name",
            MAX("upload_time") AS latest_upload
        FROM PYPI.PYPI.DISTRIBUTION_METADATA
        GROUP BY "name"
    ) lt
      ON dm."name" = lt."name"
     AND dm."upload_time" = lt.latest_upload
),
github_links AS (          -- extract & clean GitHub URLs
    SELECT
        dc."project",
        dc.download_count,
        REGEXP_REPLACE(
            REGEXP_SUBSTR(pu.value::STRING,
                           'https?://github\\.com/[^\\s,)]+'),
            '/(issues|pull|blob|tree).*',
            ''
        ) AS clean_url
    FROM download_counts dc
    JOIN latest_metadata lm
      ON dc."project" = lm."name",
    LATERAL FLATTEN(input => lm."project_urls") pu
    WHERE pu.value::STRING ILIKE '%github.com%'
),
dedup AS (                  -- one URL per project
    SELECT
        "project",
        download_count,
        clean_url,
        ROW_NUMBER() OVER (PARTITION BY "project" ORDER BY clean_url) AS rn
    FROM github_links
    WHERE clean_url IS NOT NULL
)
SELECT clean_url
FROM dedup
WHERE rn = 1
ORDER BY download_count DESC NULLS LAST
LIMIT 3;