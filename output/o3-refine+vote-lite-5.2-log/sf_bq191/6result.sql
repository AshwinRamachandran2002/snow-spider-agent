SELECT
       stats."repo_name",
       stats."watcher_count"
FROM (
        /* Aggregate 2017 WatchEvent rows by repository */
        SELECT
               "repo":"name"::STRING                    AS "repo_name",
               COUNT(DISTINCT "actor":"id"::STRING)     AS "watcher_count"
        FROM   GITHUB_REPOS_DATE.YEAR."_2017"
        WHERE  "type" = 'WatchEvent'
        GROUP  BY "repo":"name"::STRING
        HAVING COUNT(DISTINCT "actor":"id"::STRING) > 300
     ) AS stats
JOIN  (
        SELECT DISTINCT "repo_name"
        FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
      ) AS sf
  ON  sf."repo_name" = stats."repo_name"
ORDER BY stats."watcher_count" DESC NULLS LAST,
         stats."repo_name"      ASC
LIMIT 2;