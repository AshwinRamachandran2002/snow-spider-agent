WITH latest_meta AS (     -- most recent version of every package
    SELECT
        "name",
        "project_urls",
        "home_page",
        "upload_time",
        ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY "upload_time" DESC) AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
    QUALIFY rn = 1
),
github_urls AS (          -- pull & clean a GitHub repo URL
    SELECT
        m."name",
        REGEXP_REPLACE(                                            -- keep owner/repo only
            REGEXP_SUBSTR(                                         -- first GitHub URL found
                LOWER(
                    CONCAT_WS( ' ',
                        COALESCE(TO_VARCHAR(m."project_urls"), ''),
                        COALESCE(m."home_page", '')
                    )
                ),
                'https?://github\\.com/[^\\s,"/]+'                 -- github URL up to next slash/space/comma
            ),
            '(https?://github\\.com/[^/]+/[^/]+).*',               -- trim deeper paths
            '\\1'
        ) AS cleaned_url
    FROM latest_meta m
),
downloads AS (            -- total download count per package
    SELECT
        LOWER("project") AS name,
        COUNT(*)         AS download_count
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY LOWER("project")
),
ranked AS (               -- join counts with GitHub repos
    SELECT
        d.download_count,
        g.cleaned_url
    FROM downloads d
    JOIN github_urls g
      ON LOWER(g."name") = d.name
    WHERE g.cleaned_url IS NOT NULL
)
SELECT cleaned_url
FROM ranked
ORDER BY download_count DESC NULLS LAST
LIMIT 3;