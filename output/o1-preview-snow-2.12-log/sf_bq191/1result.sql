SELECT watch_counts."repo_name", watch_counts."distinct_watcher_count" AS "watcher_count"
FROM (
  SELECT "repo":"name"::STRING AS "repo_name",
         COUNT(DISTINCT "actor":"login"::STRING) AS "distinct_watcher_count"
  FROM GITHUB_REPOS_DATE.YEAR."_2017"
  WHERE "type" = 'WatchEvent'
  GROUP BY "repo":"name"::STRING
  HAVING COUNT(DISTINCT "actor":"login"::STRING) > 300
) AS watch_counts
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS."SAMPLE_FILES" AS sf
  ON watch_counts."repo_name" = sf."repo_name"
ORDER BY watch_counts."distinct_watcher_count" DESC NULLS LAST
LIMIT 2;