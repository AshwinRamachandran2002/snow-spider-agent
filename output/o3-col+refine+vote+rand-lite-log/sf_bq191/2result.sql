WITH watcher_cte AS (
    SELECT
        "repo":"name"::STRING                         AS repo_full_name,
        COUNT(DISTINCT "actor":"login"::STRING)       AS distinct_watchers
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
    GROUP BY repo_full_name
    HAVING COUNT(DISTINCT "actor":"login"::STRING) > 300
)

SELECT
    sf."repo_name",
    w.distinct_watchers
FROM watcher_cte AS w
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES AS sf
      ON w.repo_full_name = sf."repo_name"
GROUP BY
    sf."repo_name",
    w.distinct_watchers
ORDER BY
    w.distinct_watchers DESC NULLS LAST
LIMIT 2;