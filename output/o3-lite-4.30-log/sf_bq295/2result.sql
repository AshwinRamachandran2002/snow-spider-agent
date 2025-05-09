WITH watch_events_2017 AS (
    SELECT 
        "repo":"name"::STRING  AS "repo_name",
        COUNT(*)               AS "watch_event_count"
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
    GROUP BY "repo_name"
),
qualified_python_repos AS (
    SELECT DISTINCT
        "sample_repo_name" AS "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.py'
      AND "size" < 15000
      AND "content" ILIKE '%def %'
)
SELECT 
    w."repo_name"        AS repository,
    w."watch_event_count"
FROM watch_events_2017 w
JOIN qualified_python_repos p
  ON w."repo_name" = p."repo_name"
ORDER BY w."watch_event_count" DESC NULLS LAST,
         w."repo_name"        ASC
LIMIT 3;