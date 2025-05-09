WITH qualifying_repos AS (
    SELECT DISTINCT
           "sample_repo_name" AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "sample_path" ILIKE '%.py'          -- Python files only
      AND  "size" < 15000                      -- < 15 KB
      AND  "content" ILIKE '%def %'            -- contains “def ”
),
watch_counts AS (
    SELECT
        "repo":"name"::STRING  AS repo_name,
        COUNT(*)               AS watch_events_2017
    FROM   GITHUB_REPOS_DATE.YEAR._2017
    WHERE  "type" = 'WatchEvent'               -- 2017 watch events
    GROUP BY "repo":"name"::STRING
)
SELECT  w.repo_name,
        w.watch_events_2017
FROM    watch_counts w
JOIN    qualifying_repos q
       ON w.repo_name = q.repo_name
ORDER BY w.watch_events_2017 DESC NULLS LAST
LIMIT 3;