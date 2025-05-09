WITH april_events AS (
    SELECT
        "repo":"name"::string AS repo_name,
        "type"
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "type" IN ('ForkEvent', 'IssuesEvent', 'WatchEvent')
      AND EXTRACT(year  FROM TO_TIMESTAMP("created_at" / 1000000)) = 2022
      AND EXTRACT(month FROM TO_TIMESTAMP("created_at" / 1000000)) = 4
),
combined_totals AS (
    SELECT
        repo_name,
        COUNT(*) AS combined_total
    FROM april_events
    GROUP BY repo_name
),
licensed_repos AS (
    SELECT
        c.repo_name,
        c.combined_total
    FROM combined_totals c
    JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES l
      ON LOWER(c.repo_name) = LOWER(l."repo_name")
    WHERE l."license" IS NOT NULL
      AND LOWER(l."license") NOT IN ('noassertion', 'other')
)
SELECT
    repo_name,
    combined_total
FROM licensed_repos
ORDER BY combined_total DESC NULLS LAST
LIMIT 1;