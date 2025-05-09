WITH latest_metadata AS (      -- newest metadata per package
    SELECT
        "name",
        "project_urls",
        ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY "upload_time" DESC) AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
),
downloads AS (                 -- total download count per package
    SELECT
        "project" AS "name",
        COUNT(*) AS download_cnt
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
top3 AS (                      -- top-3 most-downloaded packages (with latest metadata)
    SELECT
        d."name",
        d.download_cnt,
        m."project_urls"
    FROM downloads d
    JOIN latest_metadata m
          ON m."name" = d."name"
    WHERE m.rn = 1
    ORDER BY d.download_cnt DESC NULLS LAST
    LIMIT 3
),
clean_github AS (              -- extract & clean GitHub repo URLs
    SELECT DISTINCT
        REGEXP_REPLACE(
            REGEXP_SUBSTR(                         -- grab the URL part
                f.value::STRING,
                'https?://github\\.com/[^\\s,"]+',
                1, 1, 'i'
            ),
            '/(issues|pull|blob|tree).*',          -- strip trailing paths
            '',
            1, 0, 'i'
        ) AS github_repo_url,
        t.download_cnt
    FROM top3 t,
         LATERAL FLATTEN(input => t."project_urls") f
    WHERE f.value::STRING ILIKE '%github.com%'     -- keep only GitHub links
)
SELECT github_repo_url
FROM clean_github
WHERE github_repo_url IS NOT NULL
ORDER BY download_cnt DESC NULLS LAST;