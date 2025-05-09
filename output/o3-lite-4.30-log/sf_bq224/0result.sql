WITH approved_repos AS (
    SELECT DISTINCT "repo_name"::STRING AS repo_name
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") IN (
        'apache-2.0','mit','gpl-2.0','gpl-3.0','lgpl-2.1','lgpl-3.0',
        'agpl-3.0','mpl-2.0','bsd-2-clause','bsd-3-clause','epl-1.0',
        'isc','unlicense','cc0-1.0','artistic-2.0'
    )
),
apr22_activity AS (
    SELECT
        "repo":"name"::STRING                                   AS repo_name,
        SUM(CASE WHEN "type" = 'ForkEvent'   THEN 1 ELSE 0 END) AS forks,
        SUM(CASE WHEN "type" = 'IssuesEvent' THEN 1 ELSE 0 END) AS issues,
        SUM(CASE WHEN "type" = 'WatchEvent'  THEN 1 ELSE 0 END) AS watches
    FROM GITHUB_REPOS_DATE.YEAR._2022
    WHERE "type" IN ('ForkEvent','IssuesEvent','WatchEvent')
      AND "created_at" BETWEEN 1648771200000000 AND 1651363199000000   -- 1‑Apr‑2022 to 30‑Apr‑2022 (µs)
    GROUP BY 1
)
SELECT
    a.repo_name                             AS repository,
    (a.forks + a.issues + a.watches)        AS total_forks_issues_watches
FROM apr22_activity a
JOIN approved_repos  r
  ON a.repo_name = r.repo_name
ORDER BY total_forks_issues_watches DESC NULLS LAST,
         repository
LIMIT 1;