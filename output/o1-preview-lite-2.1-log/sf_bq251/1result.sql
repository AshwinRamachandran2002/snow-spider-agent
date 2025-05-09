WITH download_counts AS (
    SELECT
        "project",
        COUNT(*) AS "download_count"
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
latest_uploads AS (
    SELECT
        "name",
        MAX("upload_time") AS "latest_upload_time",
        "project_urls"
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
    GROUP BY "name", "project_urls"
),
project_info AS (
    SELECT
        dc."project",
        dc."download_count",
        lu."latest_upload_time",
        lu."project_urls"
    FROM download_counts dc
    JOIN latest_uploads lu
        ON dc."project" = lu."name"
),
parsed_urls AS (
    SELECT
        pi."project",
        pi."download_count",
        pi."latest_upload_time",
        SPLIT_PART(f.value::STRING, ', ', 2) AS "url"
    FROM project_info pi,
         LATERAL FLATTEN(INPUT => TRY_PARSE_JSON(pi."project_urls")) f
    WHERE (f.value::STRING LIKE 'Repository,%' OR f.value::STRING LIKE 'Source,%')
          AND f.value::STRING IS NOT NULL
),
filtered_urls AS (
    SELECT
        "project",
        "download_count",
        "latest_upload_time",
        "url"
    FROM parsed_urls
    WHERE "url" LIKE 'https://github.com/%'
      AND NOT (
          "url" ILIKE '%/issues%' OR
          "url" ILIKE '%/blob/%' OR
          "url" ILIKE '%/pull/%' OR
          "url" ILIKE '%/tree/%' OR
          "url" ILIKE '%/wiki%'
      )
)
SELECT
    "url" AS "GitHub_URL"
FROM filtered_urls
ORDER BY "download_count" DESC, "latest_upload_time" DESC NULLS LAST
LIMIT 1;