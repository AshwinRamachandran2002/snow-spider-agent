WITH latest_meta AS (   -- most-recent release for each package
    SELECT
        "name",
        "upload_time",
        COALESCE("home_page", '')                       AS home_page,
        COALESCE("project_urls", '')::STRING            AS project_urls,
        ROW_NUMBER() OVER (PARTITION BY "name"
                           ORDER BY "upload_time" DESC) AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
),
meta_with_url AS (      -- extract & tidy GitHub repo URL
    SELECT
        "name",
        REGEXP_REPLACE(
            RTRIM(
                REGEXP_SUBSTR(
                    LOWER(home_page || ' ' || project_urls),
                    'https?://github\\.com/[^/\\s]+/[^/\\s]+'
                ),
                '/'
            ),
            '/(issues|pull|pulls|blob|tree|wiki)(/.*)?',
            ''
        ) AS github_url
    FROM latest_meta
    WHERE rn = 1
),
downloads AS (          -- total downloads per package
    SELECT
        LOWER("project")          AS name,
        COUNT(*)                  AS download_count
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY LOWER("project")
)
SELECT m.github_url
FROM   meta_with_url AS m
JOIN   downloads     AS d
  ON   LOWER(m."name") = d.name
WHERE  m.github_url IS NOT NULL
  AND  m.github_url <> ''
ORDER BY d.download_count DESC NULLS LAST
LIMIT 3;