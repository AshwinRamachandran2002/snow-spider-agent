WITH april22_events AS (
    SELECT
        LOWER(CAST("repo":"name" AS TEXT))                         AS repo_name,
        IFF("type" = 'ForkEvent',   1, 0)                          AS fork_cnt,
        IFF("type" = 'IssuesEvent', 1, 0)                          AS issue_cnt,
        IFF("type" = 'WatchEvent',  1, 0)                          AS watch_cnt
    FROM GITHUB_REPOS_DATE.YEAR._2022
    WHERE "type" IN ('ForkEvent', 'IssuesEvent', 'WatchEvent')
      -- convert micro‑seconds to seconds, then to DATE and keep only April‑2022 events
      AND TO_DATE(TO_TIMESTAMP_LTZ("created_at" / 1000000)) BETWEEN '2022-04-01' AND '2022-04-30'
), totals AS (
    SELECT
        repo_name,
        SUM(fork_cnt)                           AS forks,
        SUM(issue_cnt)                          AS issues,
        SUM(watch_cnt)                          AS watches,
        SUM(fork_cnt + issue_cnt + watch_cnt)   AS total_actions
    FROM april22_events
    GROUP BY repo_name
), licensed AS (
    SELECT DISTINCT LOWER("repo_name") AS repo_name
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE "license" IS NOT NULL           -- repositories having an approved license
)
SELECT
    t.repo_name,
    t.total_actions
FROM totals t
JOIN licensed l
      ON t.repo_name = l.repo_name
ORDER BY t.total_actions DESC NULLS LAST, t.repo_name
LIMIT 1;