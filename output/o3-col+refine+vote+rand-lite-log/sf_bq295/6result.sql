WITH python_repos AS (
    /* Repositories that contain at least one small Python file (<15 000 B) with “def ” */
    SELECT DISTINCT
           "sample_repo_name" AS "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  LOWER("sample_path") LIKE '%.py'          -- .py files
      AND  "size" < 15000                            -- smaller than 15 000 bytes
      AND  "content" ILIKE '%def %'                  -- contains the substring "def "
),
watch_events_2017 AS (
    /* All WatchEvents from 2017 with extracted repository names */
    SELECT
           t."repo":"name"::STRING AS "repo_name"
    FROM   GITHUB_REPOS_DATE.YEAR."_2017" t
    WHERE  t."type" = 'WatchEvent'
)
SELECT
       w."repo_name",
       COUNT(*) AS "watch_event_count"
FROM       watch_events_2017 w
INNER JOIN python_repos      p
        ON w."repo_name" = p."repo_name"
GROUP BY   w."repo_name"
ORDER BY   "watch_event_count" DESC NULLS LAST
LIMIT 3;