WITH watch_events AS (
    SELECT
        "repo":"name"::STRING AS repo_name,
        COUNT(*)             AS watch_events_2017
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
    GROUP BY repo_name
),
python_repos AS (
    SELECT DISTINCT
        "sample_repo_name" AS repo_name
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.py'
      AND "size" < 15000
      AND "content" ILIKE '%def %'
)
SELECT
    w.repo_name,
    w.watch_events_2017
FROM watch_events w
JOIN python_repos p
  ON w.repo_name = p.repo_name
ORDER BY w.watch_events_2017 DESC NULLS LAST
LIMIT 3;