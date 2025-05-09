SELECT
  w."repo_name",
  w."watcher_cnt"
FROM (
  SELECT
    "repo":"name"::STRING                               AS "repo_name",
    COUNT(DISTINCT "actor":"login"::STRING)            AS "watcher_cnt"
  FROM GITHUB_REPOS_DATE.YEAR."_2017"
  WHERE "type" = 'WatchEvent'
  GROUP BY "repo_name"
  HAVING COUNT(DISTINCT "actor":"login"::STRING) > 300
) AS w
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES AS sf
  ON w."repo_name" = sf."repo_name"
GROUP BY
  w."repo_name",
  w."watcher_cnt"
ORDER BY
  w."watcher_cnt" DESC NULLS LAST
LIMIT 2;