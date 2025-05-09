WITH events_april AS (
    SELECT
        "repo":"name"::string                                   AS repo_name,
        CASE WHEN "type" = 'WatchEvent'   THEN "actor":"id"::string END AS watch_actor,
        CASE WHEN "type" = 'IssuesEvent'  THEN 1                     END AS issue_flag,
        CASE WHEN "type" = 'ForkEvent'    THEN 1                     END AS fork_flag
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "type" IN ('WatchEvent','IssuesEvent','ForkEvent')
      AND DATE(TO_TIMESTAMP_LTZ("created_at" / 1000000))
          BETWEEN '2022-04-01' AND '2022-04-30'
), aggregated AS (
    SELECT
        repo_name,
        COUNT(DISTINCT watch_actor)                        AS watch_cnt,
        COALESCE(SUM(issue_flag),0)                        AS issue_cnt,
        COALESCE(SUM(fork_flag),0)                         AS fork_cnt,
        COUNT(DISTINCT watch_actor)
          + COALESCE(SUM(issue_flag),0)
          + COALESCE(SUM(fork_flag),0)                     AS combined_metric
    FROM events_april
    GROUP BY repo_name
), licensed_repos AS (
    SELECT "repo_name" AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE  LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
), python_repos AS (
    SELECT DISTINCT "repo_name" AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE  "ref"  = 'refs/heads/master'
      AND  LOWER("path") LIKE '%.py'
)
SELECT 
    a.repo_name,
    a.combined_metric
FROM aggregated      a
JOIN licensed_repos  l ON a.repo_name = l.repo_name
JOIN python_repos    p ON a.repo_name = p.repo_name
ORDER BY a.combined_metric DESC NULLS LAST
LIMIT 1;