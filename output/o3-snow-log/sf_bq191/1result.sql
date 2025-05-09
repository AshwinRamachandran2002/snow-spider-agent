WITH watch_counts AS (
    /* 1.  Get distinct watcher counts (only WatchEvent) for every repository in 2017 */
    SELECT
        "repo":"name"::string                         AS repo_name ,
        COUNT(DISTINCT "actor":"login"::string)       AS distinct_watchers
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
    GROUP BY repo_name
    HAVING COUNT(DISTINCT "actor":"login"::string) > 300   -- keep repos with > 300 watchers
)

SELECT DISTINCT                -- 2.  Keep each repo once after joining to SAMPLE_FILES
       wc.repo_name ,
       wc.distinct_watchers
FROM   watch_counts  wc
JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES sf
       ON wc.repo_name = sf."repo_name"
ORDER BY wc.distinct_watchers DESC NULLS LAST
LIMIT 2;