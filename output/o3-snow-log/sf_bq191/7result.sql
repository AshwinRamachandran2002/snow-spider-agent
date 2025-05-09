WITH watch_counts AS (
    /* Count distinct watchers for each repository in 2017 WatchEvents */
    SELECT
        t."repo":"name"::STRING                    AS repo_name,
        COUNT(DISTINCT t."actor":"login"::STRING)  AS watcher_count
    FROM GITHUB_REPOS_DATE.YEAR."_2017" AS t
    WHERE t."type" = 'WatchEvent'
    GROUP BY t."repo":"name"::STRING
    HAVING COUNT(DISTINCT t."actor":"login"::STRING) > 300   -- repos with >300 distinct watchers
)
SELECT
    wc.repo_name,
    wc.watcher_count
FROM watch_counts AS wc
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES AS sf
  ON sf."repo_name" = wc.repo_name
GROUP BY wc.repo_name, wc.watcher_count
ORDER BY wc.watcher_count DESC NULLS LAST
LIMIT 2;