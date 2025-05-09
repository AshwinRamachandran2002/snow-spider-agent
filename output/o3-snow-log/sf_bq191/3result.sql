WITH watch_events AS (
    /* extract repo and actor ids from 2017 WatchEvents */
    SELECT
        "repo":"name"::string  AS repo_name,
        "actor":"id"::string   AS actor_id
    FROM GITHUB_REPOS_DATE.YEAR."_2017"
    WHERE "type" = 'WatchEvent'
), agg AS (
    /* repositories with more than 300 distinct watchers */
    SELECT
        repo_name,
        COUNT(DISTINCT actor_id) AS distinct_watchers
    FROM watch_events
    GROUP BY repo_name
    HAVING COUNT(DISTINCT actor_id) > 300
), sample_repos AS (
    /* repos that exist in SAMPLE_FILES */
    SELECT DISTINCT
        "repo_name" AS repo_name
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
)
SELECT
    a.repo_name,
    a.distinct_watchers
FROM agg a
JOIN sample_repos s
  ON a.repo_name = s.repo_name
ORDER BY a.distinct_watchers DESC NULLS LAST
LIMIT 2;