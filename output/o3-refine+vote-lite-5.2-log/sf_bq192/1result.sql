/* most‑active Python repo in April‑2022 (Snowflake dialect) */
WITH py_repos AS (           -- repos that have .py files on the master branch
    SELECT DISTINCT "repo_name"  AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE  "ref"  = 'refs/heads/master'
      AND  LOWER("path") LIKE '%.py'
),
licensed_repos AS (          -- keep only wanted OSS licenses
    SELECT DISTINCT "repo_name"  AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE  LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),
watchers AS (                -- static watch counts
    SELECT "repo_name"  AS repo_name,
           MAX("watch_count") AS watch_count
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS
    GROUP  BY "repo_name"
),
events AS (                  -- issue + fork events that happened in Apr‑2022
    SELECT
        "repo":"name"::string                 AS repo_name,
        SUM(CASE WHEN "type" = 'IssuesEvent' THEN 1 ELSE 0 END) AS issue_cnt,
        SUM(CASE WHEN "type" = 'ForkEvent'   THEN 1 ELSE 0 END) AS fork_cnt
    FROM   GITHUB_REPOS_DATE.YEAR._2022
    WHERE  TO_TIMESTAMP_LTZ("created_at" / 1000000) >= '2022-04-01'
      AND  TO_TIMESTAMP_LTZ("created_at" / 1000000) <  '2022-05-01'
      AND  "type" IN ('IssuesEvent','ForkEvent')
    GROUP  BY repo_name
),
combined AS (                -- join everything and build activity score
    SELECT
        e.repo_name,
        COALESCE(e.fork_cnt,0)               AS forks,
        COALESCE(e.issue_cnt,0)              AS issues,
        COALESCE(w.watch_count,0)            AS watches,
        COALESCE(e.fork_cnt,0)
      + COALESCE(e.issue_cnt,0)
      + COALESCE(w.watch_count,0)            AS total_activity
    FROM   events           e
    LEFT  JOIN watchers     w ON e.repo_name = w.repo_name
    INNER JOIN licensed_repos l ON e.repo_name = l.repo_name
    INNER JOIN py_repos     p ON e.repo_name = p.repo_name
)
SELECT  repo_name,
        total_activity
FROM    combined
ORDER BY total_activity DESC NULLS LAST
LIMIT   1;