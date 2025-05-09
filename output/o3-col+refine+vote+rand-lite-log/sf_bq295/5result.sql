WITH python_repos AS (   -- repos that have at least one small *.py file containing "def "
    SELECT DISTINCT f."repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES     AS f
    JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS  AS c
          ON f."id" = c."id"
    WHERE LOWER(f."path") LIKE '%.py'        -- Python file
      AND c."size" < 15000                  -- < 15 KB
      AND c."content" ILIKE '%def %'        -- contains “def ”
),
watch_counts AS (        -- 2017 watch-event totals per repository
    SELECT
        e."repo"::VARIANT:"name"::STRING        AS "repo_name",
        COUNT(*)                                AS "watch_events_2017"
    FROM GITHUB_REPOS_DATE.YEAR."_2017" AS e
    WHERE e."type" = 'WatchEvent'
    GROUP BY e."repo"::VARIANT:"name"::STRING
)
SELECT
    w."repo_name",
    w."watch_events_2017"
FROM watch_counts  AS w
JOIN python_repos  AS p  ON w."repo_name" = p."repo_name"
ORDER BY w."watch_events_2017" DESC NULLS LAST
LIMIT 3;