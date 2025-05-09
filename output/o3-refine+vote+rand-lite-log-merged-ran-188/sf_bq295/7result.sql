WITH python_repos AS (
    SELECT DISTINCT
           "sample_repo_name" AS "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.py'          -- Python files
      AND "size" < 15000                            -- < 15 000 bytes
      AND "content" ILIKE '%def %'                  -- contains “def ”
),
watch_events_2017 AS (
    SELECT
        "repo":"name"::string AS "repo_name",        -- full repo name
        COUNT(*)            AS "watch_events"
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'                      -- only WatchEvents
    GROUP BY "repo_name"
)
SELECT
       w."repo_name",
       w."watch_events"
FROM watch_events_2017 w
JOIN python_repos p
  ON w."repo_name" = p."repo_name"                   -- keep repos with a qualifying .py file
ORDER BY
       w."watch_events" DESC NULLS LAST,             -- highest watch counts first
       w."repo_name"                                 -- tie‑breaker
LIMIT 3;