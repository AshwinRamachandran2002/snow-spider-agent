WITH latest_pkg AS (          -- most-recent release for every package
    SELECT *
    FROM (
        SELECT dm.*,
               ROW_NUMBER() OVER (PARTITION BY dm."name"
                                  ORDER BY dm."upload_time" DESC) AS rn
        FROM PYPI.PYPI.DISTRIBUTION_METADATA dm
    )
    WHERE rn = 1
),
github_urls AS (              -- clean GitHub repository URLs
    SELECT
        lp."name",
        REGEXP_REPLACE(                         -- drop trailing paths like issues/blob/…
            REGEXP_SUBSTR(                      -- keep only the https://github.com/… part
                f.value::STRING,
                'https?://github\.com/[^,\s]+'  -- first GitHub URL in the entry
            ),
            '/(issues|pull|blob|tree)(/.*)?$',
            ''
        ) AS github_url
    FROM latest_pkg lp,
         LATERAL FLATTEN(input => lp."project_urls") f
    WHERE f.value::STRING ILIKE '%github.com%'
),
download_counts AS (          -- total download count per project
    SELECT
        "project" AS "name",
        COUNT(*)  AS download_cnt
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
pkg_rank AS (                 -- choose one URL per package & rank by downloads
    SELECT
        dc.download_cnt,
        gu.github_url,
        ROW_NUMBER() OVER (PARTITION BY dc."name"
                           ORDER BY gu.github_url) AS url_rnk
    FROM download_counts dc
    JOIN github_urls   gu ON gu."name" = dc."name"
)
SELECT github_url
FROM pkg_rank
WHERE url_rnk = 1                     -- single cleaned URL per package
ORDER BY download_cnt DESC NULLS LAST -- most-downloaded first
LIMIT 3;