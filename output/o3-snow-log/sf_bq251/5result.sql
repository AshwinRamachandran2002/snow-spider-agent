WITH latest_metadata AS (
    SELECT
        "name",
        "version",
        "project_urls",
        "upload_time",
        ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY "upload_time" DESC) AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
),
current_release AS (
    SELECT
        "name",
        "project_urls"
    FROM latest_metadata
    WHERE rn = 1
),
github_links AS (
    SELECT
        cr."name",
        LOWER(
            REGEXP_REPLACE(
                REGEXP_SUBSTR(f.value::string, 'https?://[^ ]+'),
                '/(issues|pull|blob|tree)(/.*)?$',
                ''
            )
        ) AS repo_url
    FROM current_release cr,
         LATERAL FLATTEN( input => TRY_PARSE_JSON(cr."project_urls") ) f
    WHERE REGEXP_SUBSTR(f.value::string, 'https?://[^ ]+') ILIKE '%github.com/%'
),
download_counts AS (
    SELECT
        "project"                          AS name,
        COUNT(*)                           AS dl_count
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
combined AS (
    SELECT
        gl.repo_url,
        dc.dl_count
    FROM github_links gl
    JOIN download_counts dc
      ON gl."name" = dc.name
    QUALIFY ROW_NUMBER() OVER (PARTITION BY gl."name" ORDER BY dc.dl_count DESC) = 1
)
SELECT repo_url
FROM (
    SELECT
        repo_url,
        dl_count,
        ROW_NUMBER() OVER (ORDER BY dl_count DESC NULLS LAST) AS rnk
    FROM combined
)
WHERE rnk <= 3
ORDER BY rnk;