WITH watch_counts AS (
    /* 1. Count distinct watchers per repo from 2017 WatchEvent data */
    SELECT
        "repo":"name"::string                          AS "repo_name",
        COUNT(DISTINCT "actor":"login"::string)        AS "watcher_count"
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
    GROUP BY "repo":"name"
    HAVING COUNT(DISTINCT "actor":"login"::string) > 300
), sample_repos AS (
    /* 2. Repos that exist in SAMPLE_FILES */
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
)
SELECT
    wc."repo_name",
    wc."watcher_count"
FROM watch_counts wc
JOIN sample_repos sr
  ON wc."repo_name" = sr."repo_name"
ORDER BY
    wc."watcher_count" DESC NULLS LAST,
    wc."repo_name"
LIMIT 2;