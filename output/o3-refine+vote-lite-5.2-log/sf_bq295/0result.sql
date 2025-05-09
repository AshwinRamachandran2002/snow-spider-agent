WITH "python_repos" AS (
    SELECT DISTINCT F."repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES        F
    JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS     C
      ON F."id" = C."id"
    WHERE LOWER(F."path") LIKE '%.py'          -- Python file
      AND C."size" < 15000                    -- < 15 KB
      AND C."content" ILIKE '%def %'          -- contains the substring "def "
),
"watch_counts" AS (
    SELECT
        COALESCE(
            "repo":"full_name"::string,
            "repo":"name"::string
        )                                      AS "repo_name",
        COUNT(*)                               AS "watch_events"
    FROM GITHUB_REPOS_DATE.YEAR._2017
    WHERE "type" = 'WatchEvent'
    GROUP BY "repo_name"
)
SELECT
    W."repo_name",
    W."watch_events"
FROM "watch_counts"  W
JOIN "python_repos"  P
  ON P."repo_name" = W."repo_name"
ORDER BY
    W."watch_events" DESC NULLS LAST,
    W."repo_name"
LIMIT 3;