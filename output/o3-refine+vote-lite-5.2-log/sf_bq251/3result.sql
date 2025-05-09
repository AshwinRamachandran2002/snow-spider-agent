WITH downloads AS (                     -- total downloads per package
    SELECT
        "project"                AS "name",
        COUNT(*)                 AS "download_cnt"
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
latest_meta AS (                       -- most‑recent version per package
    SELECT *
    FROM (
        SELECT
            dm.*,
            ROW_NUMBER() OVER (
                PARTITION BY dm."name"
                ORDER BY dm."upload_time" DESC
            ) AS rn
        FROM PYPI.PYPI.DISTRIBUTION_METADATA dm
    )
    WHERE rn = 1
),
urls_home AS (                         -- GitHub URLs from home_page
    SELECT
        lm."name",
        COALESCE(d."download_cnt",0)   AS "download_cnt",
        lm."home_page"                 AS "url_str"
    FROM latest_meta lm
    LEFT JOIN downloads d
           ON lm."name" = d."name"
    WHERE lm."home_page" ILIKE '%github.com/%'
),
urls_proj AS (                         -- GitHub URLs from project_urls
    SELECT
        lm."name",
        COALESCE(d."download_cnt",0)   AS "download_cnt",
        fv.value::string               AS "url_str"
    FROM latest_meta lm
    LEFT JOIN downloads d
           ON lm."name" = d."name"
    , LATERAL FLATTEN(
          INPUT => TRY_PARSE_JSON(lm."project_urls")
      ) fv
    WHERE fv.value::string ILIKE '%github.com/%'
),
candidate_urls AS (                    -- combine both URL sources
    SELECT * FROM urls_home
    UNION ALL
    SELECT * FROM urls_proj
),
cleaned AS (                           -- clean & standardise GitHub URLs
    SELECT
        "name",
        "download_cnt",
        REGEXP_REPLACE(
            LOWER("url_str"),
            '^https?://github\\.com/([^/]+/[^/#?]+)(/.*)?$',
            'https://github.com/\\1'
        ) AS "github_url"
    FROM candidate_urls
),
per_package AS (                       -- one URL per package
    SELECT
        "name",
        MAX("download_cnt")  AS "download_cnt",
        MIN("github_url")    AS "github_url"
    FROM cleaned
    WHERE "github_url" LIKE 'https://github.com/%'
    GROUP BY "name"
)
SELECT
    "github_url"
FROM per_package
ORDER BY "download_cnt" DESC NULLS LAST, "name"
LIMIT 3;