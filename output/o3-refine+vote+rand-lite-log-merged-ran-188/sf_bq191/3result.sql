WITH watch_counts AS (
    SELECT
        "repo":"name"::string AS repo_name,
        COUNT(DISTINCT "actor":"login"::string) AS watcher_count
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
    GROUP BY "repo":"name"::string
    HAVING watcher_count > 300
),
sample_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
)
SELECT 
    w.repo_name,
    w.watcher_count
FROM watch_counts w
JOIN sample_repos s
  ON w.repo_name = s."repo_name"
ORDER BY w.watcher_count DESC NULLS LAST, w.repo_name
LIMIT 2;