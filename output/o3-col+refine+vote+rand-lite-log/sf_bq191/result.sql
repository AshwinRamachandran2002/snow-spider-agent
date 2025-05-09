WITH watch_counts AS (
    SELECT
        "repo":"name"::STRING                     AS "repo_name",
        COUNT(DISTINCT "actor":"id")              AS "distinct_watchers"
    FROM   "GITHUB_REPOS_DATE"."YEAR"."_2017"
    WHERE  "type" = 'WatchEvent'
    GROUP  BY "repo_name"
    HAVING COUNT(DISTINCT "actor":"id") > 300
)

SELECT
       wc."repo_name",
       wc."distinct_watchers"
FROM   watch_counts wc
JOIN   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES" sf
       ON sf."repo_name" = wc."repo_name"
GROUP  BY wc."repo_name", wc."distinct_watchers"
ORDER  BY wc."distinct_watchers" DESC NULLS LAST
LIMIT 2;