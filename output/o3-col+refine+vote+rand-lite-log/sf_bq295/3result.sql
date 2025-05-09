WITH py_repos AS (
    SELECT DISTINCT
           sc."sample_repo_name"          AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS sc
    WHERE  sc."sample_path" ILIKE '%.py'
      AND  sc."size" < 15000
      AND  sc."content" ILIKE '%def %'
),
watch_2017 AS (
    SELECT
           t."repo":"name"::STRING        AS repo_name,
           COUNT(*)                       AS watch_events_2017
    FROM   GITHUB_REPOS_DATE.YEAR."_2017" t
    WHERE  t."type" = 'WatchEvent'
    GROUP  BY repo_name
)
SELECT
       w.repo_name,
       w.watch_events_2017
FROM   watch_2017 w
JOIN   py_repos  p
  ON   w.repo_name = p.repo_name
ORDER  BY w.watch_events_2017 DESC NULLS LAST
LIMIT 3;