WITH watch_events AS (
    /* 1. Keep only 2017 WatchEvents and pull repo / actor */
    SELECT
        "repo":"name"::string  AS repo_name,
        "actor":"id"::string   AS actor_id
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
), watcher_counts AS (
    /* 2. Count distinct watchers per repo (need > 300) */
    SELECT
        repo_name,
        COUNT(DISTINCT actor_id) AS distinct_watchers
    FROM watch_events
    GROUP BY repo_name
    HAVING COUNT(DISTINCT actor_id) > 300
)
SELECT
    wc.repo_name,
    wc.distinct_watchers
FROM watcher_counts wc
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES sf
      ON sf."repo_name" = wc.repo_name
ORDER BY wc.distinct_watchers DESC NULLS LAST
LIMIT 2;