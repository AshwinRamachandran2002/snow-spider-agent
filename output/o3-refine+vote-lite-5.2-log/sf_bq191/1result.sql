WITH watch_events AS (
    SELECT
        "repo":"name"::string  AS repo_name,
        "actor":"id"::string   AS watcher_id
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
),
repo_watch_counts AS (
    SELECT
        repo_name,
        COUNT(DISTINCT watcher_id) AS watcher_count
    FROM watch_events
    GROUP BY repo_name
    HAVING COUNT(DISTINCT watcher_id) > 300
),
joined AS (
    SELECT
        r.repo_name,
        r.watcher_count
    FROM repo_watch_counts r
    JOIN (SELECT DISTINCT "repo_name"
          FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES) f
      ON f."repo_name" = r.repo_name
)
SELECT
    repo_name,
    watcher_count
FROM joined
ORDER BY watcher_count DESC NULLS LAST, repo_name
LIMIT 2;