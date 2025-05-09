/* ------------------------------------------------------------
   Repository with an approved license that recorded the highest
   total of forks + watches + issues during April 2022
-------------------------------------------------------------*/
WITH april_events AS (
    SELECT
        "type"                      AS event_type,
        "repo":name::STRING         AS repo_name
    FROM GITHUB_REPOS_DATE.YEAR._2022
    WHERE "created_at" >= 1648771200000000          -- 2022-04-01
      AND "created_at" <  1651363200000000          -- 2022-05-01
      AND "type" IN ('ForkEvent','WatchEvent','IssuesEvent')
),

forks AS (
    SELECT repo_name, COUNT(*) AS forks_cnt
    FROM april_events
    WHERE event_type = 'ForkEvent'
    GROUP BY repo_name
),
watches AS (
    SELECT repo_name, COUNT(*) AS watches_cnt
    FROM april_events
    WHERE event_type = 'WatchEvent'
    GROUP BY repo_name
),
issues AS (
    SELECT repo_name, COUNT(*) AS issues_cnt
    FROM april_events
    WHERE event_type = 'IssuesEvent'
    GROUP BY repo_name
),

totals AS (
    SELECT
        COALESCE(f.repo_name, w.repo_name, i.repo_name)                               AS repo_name,
        COALESCE(f.forks_cnt, 0) + COALESCE(w.watches_cnt, 0) + COALESCE(i.issues_cnt, 0) AS total_activity
    FROM forks   f
    FULL OUTER JOIN watches w ON f.repo_name = w.repo_name
    FULL OUTER JOIN issues  i ON COALESCE(f.repo_name, w.repo_name) = i.repo_name
),

approved_licenses AS (
    SELECT column1 AS license
    FROM VALUES
        ('apache-2.0'), ('mit'), ('gpl-3.0'), ('gpl-2.0'),
        ('bsd-3-clause'), ('bsd-2-clause'), ('lgpl-3.0'), ('lgpl-2.1'),
        ('mpl-2.0'), ('epl-1.0'), ('agpl-3.0'), ('isc'),
        ('artistic-2.0'), ('cc0-1.0'), ('unlicense')
)

SELECT
    t.repo_name,
    t.total_activity
FROM totals t
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES l
      ON l."repo_name" = t.repo_name
JOIN approved_licenses a
      ON a.license = l."license"
ORDER BY t.total_activity DESC NULLS LAST
LIMIT 1;