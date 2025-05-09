WITH downloads AS (      -- total download counts per package
    SELECT
        LOWER("project")          AS "name",
        COUNT(*)                  AS "download_count"
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY LOWER("project")
),
latest_meta AS (         -- newest metadata row per package
    SELECT
        LOWER("name")            AS "name",
        "project_urls",
        ROW_NUMBER() OVER (
            PARTITION BY LOWER("name")
            ORDER BY "upload_time" DESC
        )                        AS "rn"
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
),
meta_one AS (             -- keep only most‑recent rows
    SELECT
        "name",
        "project_urls"
    FROM latest_meta
    WHERE "rn" = 1
),
meta_github AS (          -- extract and clean GitHub repo URLs
    SELECT
        m."name",
        REGEXP_REPLACE(                                   -- strip issue/pull/blob/tree paths
            REGEXP_SUBSTR(                                -- first GitHub URL inside the text
                TO_VARCHAR(m."project_urls"),
                'https?://github\\.com/[^"\\s]+',         -- case-insensitive via parameter
                1, 1, 'i'
            ),
            '/(issues|pull|blob|tree)(/.*)?$',            -- remove trailing unwanted sections
            ''
        )                             AS "github_repo"
    FROM meta_one m
)
SELECT
    "github_repo"
FROM (
    SELECT
        mg."github_repo",
        d."download_count",
        ROW_NUMBER() OVER (
            ORDER BY d."download_count" DESC NULLS LAST, mg."github_repo"
        ) AS "rnk"
    FROM downloads d
    JOIN meta_github mg
      ON d."name" = mg."name"
    WHERE mg."github_repo" IS NOT NULL
      AND mg."github_repo" <> ''
)
WHERE "rnk" <= 3                 -- top 3 packages by download count
ORDER BY "rnk";