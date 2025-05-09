WITH download_counts AS (                       -- total downloads per package
    SELECT "project",
           COUNT(*) AS download_count
    FROM   "PYPI"."PYPI"."FILE_DOWNLOADS"
    GROUP  BY "project"
),
latest_release AS (                             -- newest metadata row per package
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY "name"
                                  ORDER BY "upload_time" DESC) AS rn
        FROM "PYPI"."PYPI"."DISTRIBUTION_METADATA"
    )
    WHERE rn = 1
),
raw_urls AS (                                   -- GitHub URL from project_urls or home_page
    SELECT
        lr."name" AS package_name,
        COALESCE(pu.value::STRING, lr."home_page") AS raw_url
    FROM   latest_release lr,
           LATERAL FLATTEN(input => lr."project_urls", OUTER => TRUE) pu
    WHERE  COALESCE(pu.value::STRING, lr."home_page") ILIKE '%github.com%'
),
clean_urls AS (                                 -- clean to repository root
    SELECT
        package_name,
        LOWER(
            REGEXP_REPLACE(                     -- remove unwanted path segments & trailing slashes
                REGEXP_REPLACE(
                    REGEXP_SUBSTR(raw_url, 'https?://[^\\s,]+'),
                    '/(issues|pull[^/]*|blob[^/]*|tree[^/]*)(/.*)*$',
                    ''
                ),
                '/+$', ''
            )
        ) AS github_repository_url
    FROM raw_urls
),
one_url_per_package AS (                        -- pick one URL per package
    SELECT package_name,
           MIN(github_repository_url) AS github_repository_url
    FROM   clean_urls
    GROUP  BY package_name
),
ranked AS (                                     -- rank by download count
    SELECT
        o.github_repository_url,
        ROW_NUMBER() OVER (ORDER BY dc.download_count DESC NULLS LAST) AS rk
    FROM   one_url_per_package o
           JOIN download_counts dc
             ON o.package_name = dc."project"
)
SELECT github_repository_url
FROM   ranked
WHERE  rk <= 3
ORDER  BY rk;