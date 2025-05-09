/* Which repository with an approved license had the highest
   combined number of ForkEvent, IssuesEvent and WatchEvent
   during April 2022? */

WITH
forks AS (
    SELECT
        "repo":"name"::STRING                AS repo_name,
        COUNT(*)                             AS fork_events
    FROM GITHUB_REPOS_DATE.YEAR._2022
    WHERE "type" = 'ForkEvent'
      AND "created_at" BETWEEN 1648771200000000  -- 2022-04-01
                           AND   1651363200000000  -- 2022-05-01
    GROUP BY repo_name
),
issues AS (
    SELECT
        "repo":"name"::STRING                AS repo_name,
        COUNT(*)                             AS issues_events
    FROM GITHUB_REPOS_DATE.YEAR._2022
    WHERE "type" = 'IssuesEvent'
      AND "created_at" BETWEEN 1648771200000000 AND 1651363200000000
    GROUP BY repo_name
),
watches AS (
    SELECT
        "repo":"name"::STRING                AS repo_name,
        COUNT(*)                             AS watch_events
    FROM GITHUB_REPOS_DATE.YEAR._2022
    WHERE "type" = 'WatchEvent'
      AND "created_at" BETWEEN 1648771200000000 AND 1651363200000000
    GROUP BY repo_name
),
activity AS (
    SELECT
        COALESCE(f.repo_name, i.repo_name, w.repo_name)         AS repo_name,
        COALESCE(f.fork_events, 0)   AS forks,
        COALESCE(i.issues_events, 0) AS issues,
        COALESCE(w.watch_events, 0)  AS watches,
        COALESCE(f.fork_events, 0)
      + COALESCE(i.issues_events, 0)
      + COALESCE(w.watch_events, 0)                           AS total_activity
    FROM forks   f
    FULL JOIN issues  i ON f.repo_name = i.repo_name
    FULL JOIN watches w ON COALESCE(f.repo_name, i.repo_name) = w.repo_name
)

SELECT
    a.repo_name,
    a.total_activity,
    l."license"
FROM   activity a
JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES l
  ON   a.repo_name = l."repo_name"
ORDER  BY a.total_activity DESC NULLS LAST
LIMIT 1;