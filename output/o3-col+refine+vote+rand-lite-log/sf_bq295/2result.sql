WITH python_repos AS (   -- repositories that have at least one qualifying Python file
    SELECT DISTINCT
           "sample_repo_name" AS "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.py'
      AND "size" < 15000
      AND "content" ILIKE '%def %'
),
watch_2017 AS (          -- watch-event counts per repository for 2017
    SELECT
           ("repo":"name")::STRING       AS "repo_name",
           COUNT(*)                      AS "watch_events_2017"
    FROM   GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE  "type" = 'WatchEvent'
    GROUP  BY ("repo":"name")::STRING
)
SELECT
       w."repo_name",
       w."watch_events_2017"
FROM   watch_2017 w
JOIN   python_repos p
       ON p."repo_name" = w."repo_name"
ORDER  BY w."watch_events_2017" DESC NULLS LAST
LIMIT  3;