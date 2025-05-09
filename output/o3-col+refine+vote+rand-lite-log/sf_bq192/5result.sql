WITH candidate AS (   -- Python repos on master with an approved license
    SELECT DISTINCT f."repo_name" AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES  f
    JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES      l
           ON f."repo_name" = l."repo_name"
    WHERE  f."path" ILIKE '%.py'
      AND  f."ref"  = 'refs/heads/master'
      AND ( l."license" ILIKE 'artistic%2.0'
         OR l."license" ILIKE 'isc'
         OR l."license" ILIKE 'mit'
         OR l."license" ILIKE 'apache%2.0' )
),
issues AS (          -- issue activity in April-2022
    SELECT e."repo":name::STRING  AS repo_name,
           COUNT(*)               AS issues
    FROM   GITHUB_REPOS_DATE.YEAR._2022 e
    WHERE  e."type" = 'IssuesEvent'
      AND  e."created_at" BETWEEN 1648771200000000       -- 2022-04-01 00:00 UTC
                             AND     1651363199000000     -- 2022-04-30 23:59 UTC
    GROUP BY 1
),
watches AS (         -- watch (star) activity in April-2022
    SELECT e."repo":name::STRING  AS repo_name,
           COUNT(*)               AS watches
    FROM   GITHUB_REPOS_DATE.YEAR._2022 e
    WHERE  e."type" = 'WatchEvent'
      AND  e."created_at" BETWEEN 1648771200000000 AND 1651363199000000
    GROUP BY 1
),
forks AS (           -- fork activity in April-2022
    SELECT e."repo":name::STRING  AS repo_name,
           COUNT(*)               AS forks
    FROM   GITHUB_REPOS_DATE.YEAR._2022 e
    WHERE  e."type" = 'ForkEvent'
      AND  e."created_at" BETWEEN 1648771200000000 AND 1651363199000000
    GROUP BY 1
)
SELECT  c.repo_name,
        COALESCE(f.forks ,0)
      + COALESCE(i.issues,0)
      + COALESCE(w.watches,0)   AS activity_score
FROM    candidate  c
LEFT JOIN forks    f ON c.repo_name = f.repo_name
LEFT JOIN issues   i ON c.repo_name = i.repo_name
LEFT JOIN watches  w ON c.repo_name = w.repo_name
ORDER BY activity_score DESC NULLS LAST
LIMIT 1;