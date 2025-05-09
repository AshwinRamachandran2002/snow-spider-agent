WITH watcher_counts AS (
    SELECT
        t."repo":"name"::STRING                AS "repo_name",
        COUNT(DISTINCT t."actor":"id"::STRING) AS "distinct_watcher_count"
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2017" t
    WHERE t."type" = 'WatchEvent'
    GROUP BY t."repo":"name"::STRING
    HAVING COUNT(DISTINCT t."actor":"id"::STRING) > 300
),
sample_repos AS (
    SELECT DISTINCT
           f."repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES" f
)
SELECT
    wc."repo_name",
    wc."distinct_watcher_count"
FROM watcher_counts wc
JOIN sample_repos sr
  ON wc."repo_name" = sr."repo_name"
ORDER BY wc."distinct_watcher_count" DESC NULLS LAST,
         wc."repo_name"
LIMIT 2;