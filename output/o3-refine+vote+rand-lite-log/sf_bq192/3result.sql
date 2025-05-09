WITH python_repos AS (          -- repos that really contain .py files on master
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE "ref" = 'refs/heads/master'
      AND LOWER("path") LIKE '%.py'
),
licensed_repos AS (             -- only wanted OSI licences
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),
events_apr_2022 AS (            -- all GitHub events that happened in April‑2022
    SELECT
        "repo":"name"::TEXT  AS repo_name,
        "type"               AS event_type,
        "actor":"id"::TEXT   AS actor_id
    FROM GITHUB_REPOS_DATE.YEAR._2022
    WHERE TO_TIMESTAMP("created_at") >= '2022-04-01'
      AND TO_TIMESTAMP("created_at") <  '2022-05-01'
),
watchers AS (                   -- distinct watchers (WatchEvent)
    SELECT repo_name,
           COUNT(DISTINCT actor_id) AS watch_count
    FROM events_apr_2022
    WHERE event_type = 'WatchEvent'
    GROUP BY repo_name
),
issues AS (                     -- issue events (IssuesEvent)
    SELECT repo_name,
           COUNT(*) AS issue_count
    FROM events_apr_2022
    WHERE event_type = 'IssuesEvent'
    GROUP BY repo_name
),
forks AS (                      -- forks (ForkEvent)
    SELECT repo_name,
           COUNT(*) AS fork_count
    FROM events_apr_2022
    WHERE event_type = 'ForkEvent'
    GROUP BY repo_name
),
candidate_repos AS (            -- repos satisfying licence & python‑code requirements
    SELECT pr."repo_name"
    FROM python_repos  pr
    JOIN licensed_repos lr
      ON pr."repo_name" = lr."repo_name"
)
SELECT
    cr."repo_name",
    COALESCE(f.fork_count ,0) AS "forks",
    COALESCE(i.issue_count ,0) AS "issues",
    COALESCE(w.watch_count,0) AS "watches",
    COALESCE(f.fork_count ,0)
  + COALESCE(i.issue_count ,0)
  + COALESCE(w.watch_count,0) AS "activity_score"
FROM candidate_repos cr
LEFT JOIN forks   f ON cr."repo_name" = f.repo_name
LEFT JOIN issues  i ON cr."repo_name" = i.repo_name
LEFT JOIN watchers w ON cr."repo_name" = w.repo_name
ORDER BY "activity_score" DESC NULLS LAST,
         cr."repo_name"
LIMIT 1;