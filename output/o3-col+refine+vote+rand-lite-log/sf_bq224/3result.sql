WITH april_events AS (
    SELECT
        y."repo":"name"::STRING AS repo_name
    FROM GITHUB_REPOS_DATE.YEAR."_2022" y
    WHERE y."created_at" >= 1648771200000000      -- 2022-04-01 00:00:00 UTC
      AND y."created_at" <  1651363200000000      -- 2022-05-01 00:00:00 UTC
      AND y."type" IN ('ForkEvent', 'IssuesEvent', 'WatchEvent')
),
totals AS (
    SELECT
        repo_name,
        COUNT(*) AS total_interactions
    FROM april_events
    GROUP BY repo_name
),
approved_licenses AS (
    SELECT
        "repo_name",
        "license"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE "license" IN ('mit','apache-2.0','gpl-3.0','epl-1.0','bsd-2-clause','bsd-3-clause')
)
SELECT
    t.repo_name,
    t.total_interactions,
    l."license"
FROM totals t
JOIN approved_licenses l
  ON t.repo_name = l."repo_name"
ORDER BY t.total_interactions DESC NULLS LAST
LIMIT 1;