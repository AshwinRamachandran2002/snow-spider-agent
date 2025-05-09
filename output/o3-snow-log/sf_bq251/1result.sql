WITH latest_metadata AS (
    SELECT
        "name",
        "home_page",
        "project_urls",
        "upload_time",
        ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY "upload_time" DESC) AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
),
github_candidates AS (
    SELECT
        "name",
        COALESCE("home_page", '') || ',' || COALESCE("project_urls", '') AS url_blob
    FROM latest_metadata
    WHERE rn = 1
),
extracted_github AS (
    SELECT
        "name",
        REGEXP_SUBSTR(
            url_blob,
            'https?://github\\.com/[^/\\s]+/[^/\\s]+'
        ) AS github_url_raw
    FROM github_candidates
),
cleaned_github AS (
    SELECT
        "name",
        RTRIM(github_url_raw, '/') AS github_url
    FROM extracted_github
    WHERE github_url_raw IS NOT NULL
),
download_counts AS (
    SELECT
        UPPER("project") AS name,
        COUNT(*) AS download_count
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY UPPER("project")
),
ranked AS (
    SELECT
        cg.github_url,
        dc.download_count
    FROM cleaned_github cg
    JOIN download_counts dc
      ON UPPER(cg."name") = dc.name
)
SELECT github_url
FROM ranked
ORDER BY download_count DESC NULLS LAST
LIMIT 3;