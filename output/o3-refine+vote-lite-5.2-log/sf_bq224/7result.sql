WITH april22_events AS (
    SELECT
        -- full repository name (e.g.  torvalds/linux)
        LOWER("repo":"name"::string)                         AS repo_name,

        -- indicator columns for each relevant event type
        CASE WHEN "type" = 'ForkEvent'   THEN 1 ELSE 0 END  AS fork_cnt,
        CASE WHEN "type" = 'IssuesEvent' THEN 1 ELSE 0 END  AS issue_cnt,
        CASE WHEN "type" = 'WatchEvent'  THEN 1 ELSE 0 END  AS watch_cnt
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "type" IN ('ForkEvent', 'IssuesEvent', 'WatchEvent')
          -- created_at is stored in micro‑seconds since epoch → convert to DATE
          AND TO_DATE(TO_TIMESTAMP_LTZ("created_at" / 1000000))
              BETWEEN '2022-04-01' AND '2022-04-30'
), totals AS (
    SELECT
        repo_name,
        SUM(fork_cnt)  AS forks,
        SUM(issue_cnt) AS issues,
        SUM(watch_cnt) AS watches,
        SUM(fork_cnt + issue_cnt + watch_cnt) AS total_activity
    FROM april22_events
    GROUP BY repo_name
), licensed_repos AS (
    SELECT DISTINCT LOWER("repo_name") AS repo_name
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE "license" IS NOT NULL
)
SELECT
    t.repo_name,
    t.total_activity  AS combined_forks_issues_watches,
    t.forks,
    t.issues,
    t.watches
FROM totals t
JOIN licensed_repos lr
      ON t.repo_name = lr.repo_name
ORDER BY t.total_activity DESC NULLS LAST, t.repo_name
LIMIT 1;