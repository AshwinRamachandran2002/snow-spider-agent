WITH watchers AS (
    SELECT
        "repo":"name"::STRING                               AS "repo_name",
        COUNT(DISTINCT "actor":"login"::STRING)             AS distinct_watcher_count
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2017"
    WHERE "type" = 'WatchEvent'
    GROUP BY "repo_name"
    HAVING COUNT(DISTINCT "actor":"login"::STRING) > 300
)
SELECT
    w."repo_name",
    MAX(w.distinct_watcher_count)                          AS distinct_watcher_count
FROM watchers w
JOIN "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES" f
  ON w."repo_name" = f."repo_name"
GROUP BY w."repo_name"
ORDER BY distinct_watcher_count DESC NULLS LAST, w."repo_name"
LIMIT 2;