WITH april_2022_events AS (
    SELECT
        t."repo":"name"::STRING AS "repo_name",
        COUNT(*)               AS "event_count"
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2022" t
    WHERE t."type" IN ('ForkEvent','IssuesEvent','WatchEvent')
      AND t."created_at" BETWEEN 1648771200000000     -- 2022‑04‑01 00:00:00 UTC
                           AND 1651363199000000     -- 2022‑04‑30 23:59:59 UTC
    GROUP BY 1
),
approved_repos AS (
    SELECT DISTINCT UPPER("repo_name") AS "repo_name"
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES"
    WHERE  LOWER("license") IN (
        'apache-2.0','mit','gpl-2.0','gpl-3.0','lgpl-2.1','lgpl-3.0',
        'bsd-2-clause','bsd-3-clause','mpl-2.0','epl-1.0','epl-2.0',
        'isc','artistic-2.0','agpl-3.0','cc0-1.0','unlicense'
    )
)
SELECT
       e."repo_name"            AS "repository",
       e."event_count"          AS "total_forks_issues_watches"
FROM april_2022_events e
JOIN approved_repos a
  ON UPPER(e."repo_name") = a."repo_name"
ORDER BY e."event_count" DESC NULLS LAST,
         e."repo_name"
LIMIT 1;