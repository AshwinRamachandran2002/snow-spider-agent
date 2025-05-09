WITH watch_counts AS (
    SELECT
        "repo":"name"::STRING                    AS repo_name,
        COUNT(DISTINCT "actor":"login"::STRING) AS distinct_watchers
    FROM   GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE  "type" = 'WatchEvent'
    GROUP  BY repo_name
    HAVING COUNT(DISTINCT "actor":"login"::STRING) > 300
)
SELECT  wc.repo_name,
        wc.distinct_watchers
FROM    watch_counts wc
JOIN   (SELECT DISTINCT "repo_name"
        FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES) sf
       ON wc.repo_name = sf."repo_name"
ORDER BY wc.distinct_watchers DESC NULLS LAST,
         wc.repo_name
LIMIT 2;