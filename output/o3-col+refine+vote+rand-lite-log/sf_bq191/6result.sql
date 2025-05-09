SELECT
       w.repo_name,
       w.distinct_watchers
FROM (
        SELECT
               t."repo":"name"::STRING                              AS repo_name,
               COUNT(DISTINCT t."actor":"login"::STRING)           AS distinct_watchers
        FROM   "GITHUB_REPOS_DATE"."YEAR"."_2017" t
        WHERE  t."type" = 'WatchEvent'
        GROUP  BY repo_name
        HAVING COUNT(DISTINCT t."actor":"login"::STRING) > 300
) w
JOIN  "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES" f
      ON w.repo_name = f."repo_name"
ORDER BY w.distinct_watchers DESC NULLS LAST
LIMIT 2;