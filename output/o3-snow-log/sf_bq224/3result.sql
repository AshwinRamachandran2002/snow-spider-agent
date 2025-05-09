WITH april22_events AS (          -- Fork, Issue and Watch events for April 2022
    SELECT
        "repo":"name"::STRING AS repo_name,
        "type"                AS event_type
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "type" IN ('ForkEvent', 'IssuesEvent', 'WatchEvent')
      AND TO_TIMESTAMP("created_at" / 1000000) >= '2022-04-01'
      AND TO_TIMESTAMP("created_at" / 1000000) <  '2022-05-01'
),
per_repo_counts AS (              -- aggregate counts
    SELECT
        repo_name,
        SUM(CASE WHEN event_type = 'ForkEvent'   THEN 1 ELSE 0 END) AS forks,
        SUM(CASE WHEN event_type = 'IssuesEvent' THEN 1 ELSE 0 END) AS issues,
        SUM(CASE WHEN event_type = 'WatchEvent'  THEN 1 ELSE 0 END) AS watches,
        COUNT(*)                                                    AS total
    FROM april22_events
    GROUP BY repo_name
),
licensed_repos AS (               -- repos that have an approved license
    SELECT
        c.*,
        l."license"                             -- keep original lowercase name
    FROM per_repo_counts            AS c
    JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES AS l
      ON l."repo_name" = c.repo_name
    WHERE l."license" IS NOT NULL
),
ranked AS (                        -- rank by combined total
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total DESC NULLS LAST) AS rn
    FROM licensed_repos
)
SELECT
    repo_name,
    "license",
    forks,
    issues,
    watches,
    total AS combined_total
FROM ranked
WHERE rn = 1;