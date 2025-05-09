WITH latest_meta AS (          -- most‑recent version of every package
    SELECT
        "name",
        "project_urls",
        "home_page",
        ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY "upload_time" DESC) AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
    QUALIFY rn = 1
),
extracted_urls AS (            -- gather every declared URL
    SELECT
        lm."name",
        TRIM(
              CASE
                   WHEN POSITION(',' IN f.value::STRING) > 0
                   THEN SPLIT_PART(f.value::STRING, ',', 2)   -- drop the leading label
                   ELSE f.value::STRING
              END
        ) AS url
    FROM latest_meta lm,
         LATERAL FLATTEN ( INPUT => lm."project_urls" ) f

    UNION ALL                   -- add home_page when present
    SELECT
        lm."name",
        lm."home_page" AS url
    FROM latest_meta lm
    WHERE lm."home_page" IS NOT NULL
),
github_urls AS (               -- keep & clean GitHub links
    SELECT
        eu."name",
        REGEXP_REPLACE(
              REGEXP_REPLACE(eu.url, '/(issues|pull|blob|tree).*', ''),   -- strip sub‑paths
              '/$',''                                                    -- drop trailing slash
        ) AS clean_url
    FROM extracted_urls eu
    WHERE eu.url ILIKE '%github.com/%'
),
downloads AS (                  -- total download count per project
    SELECT
        "project" AS name,
        COUNT(*) AS dl_cnt
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
ranked AS (                     -- rank repos by download count
    SELECT
        g.clean_url,
        d.dl_cnt,
        ROW_NUMBER() OVER (PARTITION BY g.clean_url ORDER BY d.dl_cnt DESC) AS rn
    FROM github_urls g
    JOIN downloads  d ON g."name" = d.name
)
SELECT
    clean_url AS github_repository_url
FROM ranked
WHERE rn = 1
ORDER BY dl_cnt DESC NULLS LAST
LIMIT 3;