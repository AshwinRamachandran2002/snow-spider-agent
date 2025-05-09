WITH watch_counts AS (
    SELECT
        ("repo"):"name"::STRING                           AS repo_name,
        COUNT(DISTINCT ("actor"):"login"::STRING)         AS watcher_count
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
    GROUP BY 1
    HAVING COUNT(DISTINCT ("actor"):"login"::STRING) > 300
)
SELECT DISTINCT
       sf."repo_name",
       wc.watcher_count
FROM   watch_counts                                            wc
JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES  sf
       ON sf."repo_name" = wc.repo_name
ORDER BY wc.watcher_count DESC NULLS LAST
LIMIT 2;