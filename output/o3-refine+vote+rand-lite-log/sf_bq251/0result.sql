WITH latest_meta AS (      -- newest version per package
    SELECT
        "name",
        "home_page",
        ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY "upload_time" DESC) AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
    WHERE "home_page" IS NOT NULL
),
github_repos AS (          -- keep only valid GitHub repo URLs
    SELECT
        "name",
        REGEXP_REPLACE(           -- drop optional ".git" suffix
            REGEXP_SUBSTR(
                "home_page",
                '^https?://github\\.com/[^/]+/[^/]+',
                1, 1, 'i'
            ),
            '\\.git$',
            '',
            1, 0, 'i'
        ) AS repo_url
    FROM latest_meta
    WHERE rn = 1
      AND REGEXP_LIKE(
              "home_page",
              '^https?://github\\.com/[^/]+/[^/]+',
              'i'
          )
),
download_counts AS (       -- total downloads per package
    SELECT
        LOWER("project") AS name,
        COUNT(*)         AS download_count
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY LOWER("project")
),
ranked AS (                -- combine and rank by downloads
    SELECT
        d.name,
        d.download_count,
        g.repo_url,
        ROW_NUMBER() OVER (ORDER BY d.download_count DESC, d.name) AS rk
    FROM download_counts d
    JOIN github_repos g
      ON LOWER(g."name") = d.name
)
SELECT repo_url
FROM ranked
WHERE rk <= 3
ORDER BY rk;