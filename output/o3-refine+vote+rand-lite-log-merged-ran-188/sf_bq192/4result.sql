/* Most‑active Python repo in April‑2022 by (forks + issues + watchers) */
WITH python_repos AS (          -- repos that contain .py files on the master branch
    SELECT DISTINCT "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE  "ref" = 'refs/heads/master'
      AND  LOWER("path") LIKE '%.py'
),
licensed AS (                   -- repos with an approved OSS licence
    SELECT  "repo_name"
    FROM    GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE   LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),
watchers AS (                   -- current watcher counts
    SELECT  "repo_name",
            "watch_count"
    FROM    GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS
),
issues_apr22 AS (               -- issue events in April 2022
    SELECT  "repo":"name"::STRING  AS "repo_name",
            COUNT(*)              AS issue_events
    FROM    GITHUB_REPOS_DATE.YEAR._2022
    WHERE   "type" = 'IssuesEvent'
      AND   TO_DATE(TO_TIMESTAMP_NTZ("created_at")) BETWEEN '2022-04-01' AND '2022-04-30'
    GROUP BY "repo_name"
),
forks_apr22 AS (                -- fork events in April 2022
    SELECT  "repo":"name"::STRING  AS "repo_name",
            COUNT(*)              AS fork_events
    FROM    GITHUB_REPOS_DATE.YEAR._2022
    WHERE   "type" = 'ForkEvent'
      AND   TO_DATE(TO_TIMESTAMP_NTZ("created_at")) BETWEEN '2022-04-01' AND '2022-04-30'
    GROUP BY "repo_name"
),
activity AS (                   -- aggregate activity metrics
    SELECT  l."repo_name",
            COALESCE(w."watch_count", 0) AS watches,
            COALESCE(i.issue_events, 0)  AS issues,
            COALESCE(f.fork_events, 0)   AS forks,
            COALESCE(w."watch_count", 0)
          + COALESCE(i.issue_events, 0)
          + COALESCE(f.fork_events, 0)   AS total_activity
    FROM    licensed       l
    JOIN    python_repos   p USING ("repo_name")
    LEFT JOIN watchers     w USING ("repo_name")
    LEFT JOIN issues_apr22 i USING ("repo_name")
    LEFT JOIN forks_apr22  f USING ("repo_name")
)
SELECT  "repo_name" AS "NAME",
        total_activity
FROM    activity
ORDER BY total_activity DESC NULLS LAST,
         "repo_name"
LIMIT 1;