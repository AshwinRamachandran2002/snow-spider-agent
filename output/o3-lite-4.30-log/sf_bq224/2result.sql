WITH april_2022_events AS (
    SELECT
        f.value:"name"::STRING AS repo_name,
        e."type"
    FROM GITHUB_REPOS_DATE.YEAR."_2022" e,
         LATERAL FLATTEN(input => ARRAY_CONSTRUCT(e."repo")) f
    WHERE e."type" IN ('ForkEvent','WatchEvent','IssuesEvent')
      AND TO_DATE(TO_TIMESTAMP_NTZ(e."created_at" / 1000000))
          BETWEEN '2022-04-01' AND '2022-04-30'
),
events_per_repo AS (
    SELECT
        repo_name,
        COUNT(*) AS total_forks_issues_watches
    FROM april_2022_events
    GROUP BY repo_name
),
approved_licenses AS (
    SELECT
        l."repo_name" AS repo_name
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES l
    WHERE l."license" IN (
        'apache-2.0','bsd-2-clause','bsd-3-clause','cc0-1.0','epl-1.0',
        'gpl-2.0','gpl-3.0','lgpl-2.1','lgpl-3.0','mit','mpl-2.0',
        'unlicense','isc','agpl-3.0','artistic-2.0'
    )
)
SELECT
    e.repo_name  AS repository,
    e.total_forks_issues_watches
FROM events_per_repo   e
JOIN approved_licenses a
  ON e.repo_name = a.repo_name
ORDER BY e.total_forks_issues_watches DESC NULLS LAST,
         e.repo_name
LIMIT 1;