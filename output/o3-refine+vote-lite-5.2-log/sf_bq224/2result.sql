WITH "LICENSE_REPOS" AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE "license" IS NOT NULL                -- approved licence present
), 
"APRIL_EVENTS" AS (
    SELECT  
        "repo":"name"::string AS "repo_name",
        "type"
    FROM GITHUB_REPOS_DATE.YEAR._2022
    WHERE "type" IN ('ForkEvent','IssuesEvent','WatchEvent')
      AND TO_TIMESTAMP("created_at" / 1000000) >= '2022-04-01'   --   1 Apr 2022
      AND TO_TIMESTAMP("created_at" / 1000000) <  '2022-05-01'   --  30 Apr 2022 23:59:59
), 
"COUNTS" AS (
    SELECT 
        "repo_name",
        COUNT(*) AS "total_events"        -- forks + issues + watches
    FROM "APRIL_EVENTS"
    GROUP BY "repo_name"
)
SELECT  c."repo_name",
        c."total_events"
FROM    "COUNTS"  c
JOIN    "LICENSE_REPOS" l 
       ON l."repo_name" = c."repo_name"
ORDER BY c."total_events" DESC NULLS LAST,
         c."repo_name"
LIMIT 1;