/* Repository that has an approved entry in LICENSES (i.e. a licence declared
   in “licenses.md”) and achieved the highest combined number of Fork, Issue,
   and Watch events in April 2022. */

WITH april22 AS (                         -- events during April-2022
    SELECT
        "type",
        "repo":"name"::STRING AS repo_name
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "created_at"
          BETWEEN 1648771200000000      -- 2022-04-01 00:00:00 UTC
              AND 1651363199000000      -- 2022-04-30 23:59:59 UTC
),
forks AS (                               -- ForkEvents per repo
    SELECT repo_name, COUNT(*) AS forks
    FROM april22
    WHERE "type" = 'ForkEvent'
    GROUP BY repo_name
),
issues AS (                              -- IssuesEvents per repo
    SELECT repo_name, COUNT(*) AS issues
    FROM april22
    WHERE "type" = 'IssuesEvent'
    GROUP BY repo_name
),
watches AS (                             -- WatchEvents (stars) per repo
    SELECT repo_name, COUNT(*) AS watches
    FROM april22
    WHERE "type" = 'WatchEvent'
    GROUP BY repo_name
),
totals AS (                              -- merge the three tallies
    SELECT
        COALESCE(f.repo_name, i.repo_name, w.repo_name)                    AS repo_name,
        COALESCE(f.forks , 0)                                             AS forks,
        COALESCE(i.issues, 0)                                             AS issues,
        COALESCE(w.watches, 0)                                            AS watches,
        COALESCE(f.forks ,0) + COALESCE(i.issues,0) + COALESCE(w.watches,0) AS total_score
    FROM forks   f
    FULL OUTER JOIN issues  i ON f.repo_name = i.repo_name
    FULL OUTER JOIN watches w ON COALESCE(f.repo_name, i.repo_name) = w.repo_name
)

SELECT
    t.repo_name,
    t.total_score
FROM totals                             t
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES l
      ON t.repo_name = l."repo_name"    -- repository has an approved licence
ORDER BY t.total_score DESC NULLS LAST
LIMIT 1;