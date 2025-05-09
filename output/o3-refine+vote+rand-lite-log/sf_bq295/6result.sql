WITH watch_counts AS (
    SELECT
        "repo":"name"::string AS "repo_name",
        COUNT(*)             AS "watch_events"
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
      AND "repo":"name" IS NOT NULL
    GROUP BY "repo_name"
),
python_repos AS (
    SELECT DISTINCT
        "sample_repo_name" AS "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.py'
      AND "size" < 15000
      AND "binary" = FALSE
      AND "content" LIKE '%def %'
)
SELECT
    w."repo_name",
    w."watch_events"
FROM watch_counts w
JOIN python_repos p
  ON w."repo_name" = p."repo_name"
ORDER BY w."watch_events" DESC NULLS LAST,
         w."repo_name"
LIMIT 3;