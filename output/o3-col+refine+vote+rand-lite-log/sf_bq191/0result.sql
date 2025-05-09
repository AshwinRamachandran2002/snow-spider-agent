/* Top-2 repositories (in 2017 WatchEvent data) with >300 distinct watchers,
   restricted to repositories that also appear in SAMPLE_FILES               */
WITH watchers AS (  -- repos & their distinct-watcher counts (>300)
    SELECT
        t."repo":"name"::STRING        AS "repo_name",
        COUNT(DISTINCT t."actor":"login"::STRING) AS "watcher_cnt"
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2017" t
    WHERE t."type" = 'WatchEvent'
    GROUP BY t."repo":"name"::STRING
    HAVING COUNT(DISTINCT t."actor":"login"::STRING) > 300
),
sample_repos AS (  -- distinct repo names present in SAMPLE_FILES
    SELECT DISTINCT
        sf."repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES" sf
)
SELECT
    w."repo_name",
    w."watcher_cnt"
FROM watchers       w
JOIN sample_repos   sr ON sr."repo_name" = w."repo_name"
ORDER BY
    w."watcher_cnt" DESC NULLS LAST
LIMIT 2;