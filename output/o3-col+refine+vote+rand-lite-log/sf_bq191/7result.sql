WITH repo_watch_counts AS (
    SELECT
        ("repo":"name")::STRING                                    AS repo_name,
        COUNT(DISTINCT ("actor":"login")::STRING)                  AS distinct_watchers
    FROM   GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE  "type" = 'WatchEvent'
    GROUP  BY repo_name
    HAVING COUNT(DISTINCT ("actor":"login")::STRING) > 300
)
SELECT
    r.repo_name,
    r.distinct_watchers
FROM   repo_watch_counts                          r
JOIN   ( SELECT DISTINCT "repo_name"
         FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES ) f
       ON f."repo_name" = r.repo_name
ORDER  BY r.distinct_watchers DESC NULLS LAST
LIMIT  2;