/* Most active Python repository in April 2022 (the higher the activity_score, the more active) */
WITH
/* Python repositories that have at least one *.py file on the master branch */
py_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE "ref" = 'refs/heads/master'
      AND LOWER("path") LIKE '%.py'
),

/* Repositories that use one of the wanted open-source licences */
licensed_repos AS (
    SELECT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),

/* Watch (star) events during April 2022 */
watchers AS (
    SELECT
        PARSE_JSON("repo"):"name"::STRING      AS repo_name,
        COUNT(DISTINCT PARSE_JSON("actor"):"login"::STRING) AS watch_cnt
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "type" = 'WatchEvent'
      AND TO_TIMESTAMP("created_at"/1000000)
          BETWEEN '2022-04-01' AND '2022-04-30 23:59:59'
    GROUP BY repo_name
),

/* Issue events during April 2022 */
issues AS (
    SELECT
        PARSE_JSON("repo"):"name"::STRING AS repo_name,
        COUNT(*)                         AS issue_cnt
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "type" = 'IssuesEvent'
      AND TO_TIMESTAMP("created_at"/1000000)
          BETWEEN '2022-04-01' AND '2022-04-30 23:59:59'
    GROUP BY repo_name
),

/* Fork events during April 2022 */
forks AS (
    SELECT
        PARSE_JSON("repo"):"name"::STRING AS repo_name,
        COUNT(*)                         AS fork_cnt
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "type" = 'ForkEvent'
      AND TO_TIMESTAMP("created_at"/1000000)
          BETWEEN '2022-04-01' AND '2022-04-30 23:59:59'
    GROUP BY repo_name
)

/* Combine everything and rank by activity */
SELECT
    l."repo_name",
    COALESCE(w.watch_cnt,0)
      + COALESCE(i.issue_cnt,0)
      + COALESCE(f.fork_cnt,0)           AS activity_score
FROM licensed_repos           l
JOIN py_repos                 p ON p."repo_name" = l."repo_name"
LEFT JOIN watchers            w ON w.repo_name   = l."repo_name"
LEFT JOIN issues              i ON i.repo_name   = l."repo_name"
LEFT JOIN forks               f ON f.repo_name   = l."repo_name"
ORDER BY activity_score DESC NULLS LAST
LIMIT 1;