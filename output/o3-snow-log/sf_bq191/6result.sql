WITH watch_events AS (
    /* All 2017 WatchEvents with repository and actor information */
    SELECT
        "repo":name::string AS repo_name,
        "actor":id::string  AS actor_id
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
), watch_counts AS (
    /* Count distinct watchers per repository; keep only those with > 300 */
    SELECT
        repo_name,
        COUNT(DISTINCT actor_id) AS watcher_count
    FROM watch_events
    GROUP BY repo_name
    HAVING COUNT(DISTINCT actor_id) > 300
), sample_repos AS (
    /* Repositories that appear in SAMPLE_FILES */
    SELECT DISTINCT "repo_name" AS repo_name
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
)
SELECT
    wc.repo_name       AS "REPO_NAME",
    wc.watcher_count   AS "DISTINCT_WATCHER_COUNT"
FROM watch_counts  wc
JOIN sample_repos  sr
      ON wc.repo_name = sr.repo_name
ORDER BY wc.watcher_count DESC NULLS LAST
LIMIT 2;