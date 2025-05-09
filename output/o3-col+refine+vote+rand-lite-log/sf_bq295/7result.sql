WITH python_repos AS (
    SELECT DISTINCT
           "sample_repo_name" AS "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  LOWER("sample_path") LIKE '%.py'          -- Python files
      AND  "size" < 15000                            -- smaller than 15 000 bytes
      AND  "content" ILIKE '%def %'                  -- containing the substring "def "
),
watch_events_2017 AS (
    SELECT
           t."repo":"name"::STRING AS "repo_name"
    FROM   GITHUB_REPOS_DATE.YEAR."_2017" t
    WHERE  t."type" = 'WatchEvent'                   -- only WatchEvent rows
)
SELECT
       w."repo_name",
       COUNT(*) AS "watch_events_2017"
FROM   watch_events_2017 w
JOIN   python_repos     p  ON w."repo_name" = p."repo_name"
GROUP  BY w."repo_name"
ORDER  BY "watch_events_2017" DESC NULLS LAST
LIMIT 3;