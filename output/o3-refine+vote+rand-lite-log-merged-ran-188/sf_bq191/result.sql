WITH watch_events AS (
    SELECT
        "repo":"name"::STRING   AS repo_name,
        "actor":"login"::STRING AS watcher_login
    FROM GITHUB_REPOS_DATE.YEAR._2017
    WHERE "type" = 'WatchEvent'
),
watch_counts AS (
    SELECT
        repo_name,
        COUNT(DISTINCT watcher_login) AS distinct_watchers
    FROM watch_events
    GROUP BY repo_name
    HAVING COUNT(DISTINCT watcher_login) > 300
),
sample_repos AS (
    SELECT DISTINCT
        "repo_name" AS repo_name      -- alias to case‑insensitive identifier
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
)
SELECT
    wc.repo_name,
    wc.distinct_watchers
FROM watch_counts wc
JOIN sample_repos sr
      ON wc.repo_name = sr.repo_name
ORDER BY
    wc.distinct_watchers DESC NULLS LAST,
    wc.repo_name
LIMIT 2;