/*-----------------------------------------------------------
  Most active Python repository (April 2022)

  – Python listed in LANGUAGES
  – At least one “*.py” file on the master branch
  – Licence in {artistic-2.0, isc, mit, apache-2.0}
  – Activity score = fork events + issue events + distinct watchers
-----------------------------------------------------------*/
WITH candidate_repos AS (          -- repos that satisfy language, licence and *.py file requirement
    SELECT DISTINCT l."repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES"      l
    JOIN "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES"       lic
          ON lic."repo_name" = l."repo_name"
    JOIN "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES"   f
          ON f."repo_name" = l."repo_name"
             AND f."ref"  = 'refs/heads/master'
             AND f."path" ILIKE '%.py'
    WHERE l."language" ILIKE '%Python%'
      AND lic."license"  IN ('artistic-2.0','isc','mit','apache-2.0')
),
apr22_events AS (                 -- all events that happened in April-2022
    SELECT
        e."type",
        e."actor":"id"::STRING     AS "actor_id",
        e."repo":"name"::STRING    AS "repo_name"
    FROM "GITHUB_REPOS_DATE"."YEAR"."_2022"  e
    WHERE e."created_at" BETWEEN 1648771200000000    -- 2022-04-01 00:00:00 UTC
                           AND     1651363199999999   -- 2022-04-30 23:59:59 UTC
)
SELECT
    c."repo_name",
    /* distinct watchers */
    COUNT(DISTINCT CASE WHEN ev."type" = 'WatchEvent' THEN ev."actor_id" END)         AS "watch_cnt",
    /* fork events */
    SUM( CASE WHEN ev."type" = 'ForkEvent'   THEN 1 ELSE 0 END )                      AS "fork_cnt",
    /* issue events */
    SUM( CASE WHEN ev."type" = 'IssuesEvent' THEN 1 ELSE 0 END )                      AS "issue_cnt",
    /* combined activity score */
    SUM( CASE WHEN ev."type" = 'ForkEvent'   THEN 1 ELSE 0 END )
  + SUM( CASE WHEN ev."type" = 'IssuesEvent' THEN 1 ELSE 0 END )
  + COUNT(DISTINCT CASE WHEN ev."type" = 'WatchEvent' THEN ev."actor_id" END)         AS "total_activity"
FROM        candidate_repos  c
LEFT JOIN   apr22_events     ev
       ON   c."repo_name" = ev."repo_name"
GROUP BY    c."repo_name"
ORDER BY    "total_activity" DESC NULLS LAST
LIMIT 1;