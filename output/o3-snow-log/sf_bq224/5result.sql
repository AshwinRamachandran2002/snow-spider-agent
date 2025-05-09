/* ---------------------------------------------------------------
   Repository with the greatest combined count of forks, issues,
   and watches during April-2022, restricted to projects whose
   license is recorded (approved) in the LICENSES table.
-----------------------------------------------------------------*/
WITH licensed_repos AS (                     -- all repos that have a recognised licence
    SELECT DISTINCT LOWER("repo_name") AS "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE  "license" IS NOT NULL
),

repo_events AS (                             -- forks + issues + watches during April-2022
    SELECT
        LOWER(e."repo":"name"::string) AS "repo_name",
        COUNT(*)                       AS "total_events"
    FROM   GITHUB_REPOS_DATE.YEAR."_2022"  e
    WHERE  e."type" IN ('ForkEvent','IssuesEvent','WatchEvent')
      AND  TO_TIMESTAMP_NTZ(e."created_at" / 1000000)
           BETWEEN '2022-04-01' AND '2022-04-30 23:59:59'
    GROUP BY 1
)

SELECT  e."repo_name",
        e."total_events"  AS "forks_issues_watches_total"
FROM    repo_events  e
JOIN    licensed_repos r
  ON    e."repo_name" = r."repo_name"
ORDER BY e."total_events" DESC NULLS LAST
LIMIT 1;