/* Top-2 repositories from 2017 WatchEvents with >300 distinct watchers
   that also appear in SAMPLE_FILES                                       */
WITH watch_events AS (
    SELECT
        "repo":name::string     AS repo_name,      -- full “owner/repo”
        "actor":login::string   AS watcher_login
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
),
watch_counts AS (
    SELECT
        repo_name,
        COUNT(DISTINCT watcher_login) AS distinct_watchers
    FROM watch_events
    GROUP BY repo_name
    HAVING COUNT(DISTINCT watcher_login) > 300
)
SELECT
    wc.repo_name,
    wc.distinct_watchers
FROM watch_counts wc
JOIN (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
) sf
  ON wc.repo_name = sf."repo_name"
ORDER BY wc.distinct_watchers DESC NULLS LAST
LIMIT 2;