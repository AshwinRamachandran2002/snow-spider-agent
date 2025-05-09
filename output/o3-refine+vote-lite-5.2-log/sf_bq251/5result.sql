WITH latest_meta AS (   -- most‑recent metadata row for every package
    SELECT
        "name",
        "version",
        "project_urls"::string   AS project_urls
    FROM (
        SELECT
            "name",
            "version",
            "project_urls",
            "upload_time",
            ROW_NUMBER() OVER (PARTITION BY "name"
                               ORDER BY "upload_time" DESC) AS rn
        FROM PYPI.PYPI.DISTRIBUTION_METADATA
    )
    WHERE rn = 1
),
meta_github AS (        -- extract & clean github repository url
    SELECT
        "name",
        "version",
        /* 1) take first github url in the text
           2) trim to   https://github.com/<owner>/<repo>
           3) drop optional ".git" or trailing "/"                        */
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_SUBSTR(project_urls,
                                   'https?://github\\.com/[^"''\\s\\]\\}]+',
                                   1, 1, 'i'),
                    '(https?://github\\.com/[^/]+/[^/]+).*',
                    '\\1',
                    1, 1, 'i'),
                '\\.git$',''),
            '/$','')                                           AS github_repo
    FROM latest_meta
),
downloads AS (          -- total download count per package
    SELECT
        "project" AS name,
        COUNT(*)  AS total_downloads
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
combined AS (           -- join downloads with github repos
    SELECT
        d.total_downloads,
        m.github_repo
    FROM downloads d
    JOIN meta_github m
      ON LOWER(d.name) = LOWER(m."name")
    WHERE m.github_repo IS NOT NULL
)
SELECT github_repo
FROM combined
ORDER BY total_downloads DESC NULLS LAST, github_repo
LIMIT 3;