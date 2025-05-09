WITH watch_counts AS (
    SELECT
        "repo"::VARIANT:"name"::STRING                         AS "repo_name",
        COUNT(DISTINCT "actor"::VARIANT:"login"::STRING)       AS "watcher_cnt"
    FROM   "GITHUB_REPOS_DATE"."YEAR"."_2017"
    WHERE  "type" = 'WatchEvent'
    GROUP  BY "repo_name"
    HAVING COUNT(DISTINCT "actor"::VARIANT:"login"::STRING) > 300
)
SELECT
    wc."repo_name",
    wc."watcher_cnt"
FROM   watch_counts wc
JOIN   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES" sf
       ON sf."repo_name" = wc."repo_name"
GROUP  BY wc."repo_name", wc."watcher_cnt"
ORDER  BY wc."watcher_cnt" DESC NULLS LAST
LIMIT 2;