WITH latest AS (  -- most‑recent metadata for every package
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY "upload_time" DESC) AS rn
        FROM "PYPI"."PYPI"."DISTRIBUTION_METADATA"
    )
    WHERE rn = 1
),
downloads AS (    -- total file‑download events per package
    SELECT "project",
           COUNT(*) AS download_count
    FROM "PYPI"."PYPI"."FILE_DOWNLOADS"
    GROUP BY "project"
),
url_sources AS (  -- raw GitHub‑looking URLs from project_urls and home_page
    -- project_urls array
    SELECT
        l."name",
        REGEXP_REPLACE(
            f.value::STRING,
            '.*(https?://github\\.com/[^/]+/[^/#?]+).*',
            '\\1'
        ) AS cleaned_url
    FROM latest l,
         LATERAL FLATTEN(input => l."project_urls") f
    WHERE f.value::STRING ILIKE '%github.com/%'

    UNION ALL

    -- home_page column
    SELECT
        l."name",
        REGEXP_REPLACE(
            l."home_page",
            '.*(https?://github\\.com/[^/]+/[^/#?]+).*',
            '\\1'
        ) AS cleaned_url
    FROM latest l
    WHERE l."home_page" ILIKE '%github.com/%'
),
valid_urls AS (   -- keep only successfully cleaned GitHub repo URLs
    SELECT DISTINCT
           u."name",
           u.cleaned_url
    FROM url_sources u
    WHERE u.cleaned_url ILIKE 'http%://github.com/%'
),
combined AS (     -- join with downloads and deduplicate identical repos
    SELECT
        v.cleaned_url,
        d.download_count,
        ROW_NUMBER() OVER (PARTITION BY v.cleaned_url
                           ORDER BY d.download_count DESC) AS url_rank
    FROM valid_urls v
    JOIN downloads d
      ON v."name" = d."project"
)
SELECT cleaned_url AS github_repository_url
FROM combined
WHERE url_rank = 1
ORDER BY download_count DESC NULLS LAST, cleaned_url
LIMIT 3;