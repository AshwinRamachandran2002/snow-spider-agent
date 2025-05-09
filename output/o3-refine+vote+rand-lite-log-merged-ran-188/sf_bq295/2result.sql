WITH py_repos AS (
    SELECT DISTINCT
           f."repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS  c
         ON f."id" = c."id"
    WHERE f."path" ILIKE '%.py'           -- python file
      AND c."binary" = FALSE              -- text file
      AND c."size"  < 15000               -- smaller than 15 KB
      AND c."content" ILIKE '%def %'      -- contains “def ”
),
watch_2017 AS (
    SELECT
        "repo":"name"::STRING AS repo_name
    FROM GITHUB_REPOS_DATE.YEAR._2017
    WHERE "type" = 'WatchEvent'
)
SELECT
    w.repo_name,
    COUNT(*) AS watch_events
FROM watch_2017 w
JOIN py_repos p
  ON w.repo_name = p."repo_name"
GROUP BY w.repo_name
ORDER BY watch_events DESC NULLS LAST,
         w.repo_name
LIMIT 3;