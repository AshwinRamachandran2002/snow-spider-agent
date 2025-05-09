WITH python_repos AS (        -- repos that own at least one qualifying Python file
    SELECT DISTINCT
           "sample_repo_name" AS "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS."SAMPLE_CONTENTS"
    WHERE  "sample_path" ILIKE '%.py'      -- Python file
      AND  "size" < 15000                  -- smaller than 15 000 bytes
      AND  "content" ILIKE '%def %'        -- contains the substring “def ”
),
watch_counts AS (             -- 2017 WatchEvent totals per repository
    SELECT
           "repo":"name"::STRING AS "repo_name",
           COUNT(*)              AS "watch_events_2017"
    FROM   GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE  "type" = 'WatchEvent'
    GROUP  BY "repo_name"
)
SELECT
       w."repo_name",
       w."watch_events_2017"
FROM   watch_counts w
JOIN   python_repos p
  ON   w."repo_name" = p."repo_name"
ORDER  BY w."watch_events_2017" DESC NULLS LAST
LIMIT  3;