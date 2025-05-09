WITH "latest_meta" AS (  -- newest release per package
    SELECT
        LOWER("name")               AS "name_lower",
        "project_urls",
        ROW_NUMBER() OVER (PARTITION BY LOWER("name") ORDER BY "upload_time" DESC) AS "rn"
    FROM "PYPI"."PYPI"."DISTRIBUTION_METADATA"
),
"selected_meta" AS (     -- extract and clean first GitHub repo URL
    SELECT
        "name_lower",
        REGEXP_SUBSTR(                       -- keep only https://github.com/user/repo
            REGEXP_SUBSTR(
                LOWER("project_urls"::string),
                'https?://github\\.com/[^\\s"]+'   -- first GitHub link
            ),
            'https?://github\\.com/[^/]+/[^/]+'    -- trim to main repo path
        ) AS "github_repo"
    FROM "latest_meta"
    WHERE "rn" = 1
),
"download_counts" AS (   -- total downloads per project
    SELECT
        LOWER("project") AS "name_lower",
        COUNT(*)         AS "downloads"
    FROM "PYPI"."PYPI"."FILE_DOWNLOADS"
    GROUP BY LOWER("project")
)
SELECT
    "github_repo"
FROM "selected_meta"  sm
JOIN "download_counts" dc
  ON sm."name_lower" = dc."name_lower"
WHERE sm."github_repo" IS NOT NULL
ORDER BY dc."downloads" DESC NULLS LAST, sm."name_lower"
LIMIT 3;