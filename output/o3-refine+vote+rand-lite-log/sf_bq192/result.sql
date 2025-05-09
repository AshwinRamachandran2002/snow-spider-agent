/* Most‑active open‑source Python repository in April 2022 */
WITH python_repos AS (          -- repos that contain .py files on the master branch
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE "ref" = 'refs/heads/master'
      AND LOWER("path") LIKE '%.py'
),
licensed_repos AS (            -- repos using one of the required OSS licences
    SELECT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),
watchers AS (                   -- watcher counts (static)
    SELECT "repo_name",
           "watch_count"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS
),
issue_counts AS (               -- IssuesEvent occurring in April 2022
    SELECT "repo":"name"::text  AS repo_name,
           COUNT(*)             AS issue_cnt
    FROM   GITHUB_REPOS_DATE.YEAR._2022
    WHERE  "type" = 'IssuesEvent'
      AND  TO_TIMESTAMP_NTZ("created_at"/1000) >= '2022-04-01'
      AND  TO_TIMESTAMP_NTZ("created_at"/1000) <  '2022-05-01'
    GROUP BY repo_name
),
fork_counts AS (                -- ForkEvent occurring in April 2022
    SELECT "repo":"name"::text  AS repo_name,
           COUNT(*)             AS fork_cnt
    FROM   GITHUB_REPOS_DATE.YEAR._2022
    WHERE  "type" = 'ForkEvent'
      AND  TO_TIMESTAMP_NTZ("created_at"/1000) >= '2022-04-01'
      AND  TO_TIMESTAMP_NTZ("created_at"/1000) <  '2022-05-01'
    GROUP BY repo_name
),
combined AS (                   -- bring everything together
    SELECT l."repo_name",
           COALESCE(w."watch_count",0) AS watch_cnt,
           COALESCE(i.issue_cnt,0)     AS issue_cnt,
           COALESCE(f.fork_cnt,0)      AS fork_cnt
    FROM   licensed_repos l
    JOIN   python_repos   p ON p."repo_name" = l."repo_name"
    LEFT  JOIN watchers        w ON w."repo_name" = l."repo_name"
    LEFT  JOIN issue_counts    i ON i.repo_name = l."repo_name"
    LEFT  JOIN fork_counts     f ON f.repo_name = l."repo_name"
)
SELECT  "repo_name",
        (watch_cnt + issue_cnt + fork_cnt) AS activity_score
FROM    combined
ORDER BY activity_score DESC NULLS LAST, "repo_name"
LIMIT 1;