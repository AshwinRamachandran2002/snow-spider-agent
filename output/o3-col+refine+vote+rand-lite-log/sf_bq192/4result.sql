/*---------------------------------------------------------------
 Find the “most-active” Python repository (OSS-licensed) by
 combining:
   • watcher snapshot
   • April-2022 Issue-related events
   • April-2022 Fork events
 All counts are coalesced to 0 so that a repository without
 events or a watcher snapshot is still considered.
----------------------------------------------------------------*/
WITH python_repos AS (          -- repos that claim Python and have *.py on master
    SELECT DISTINCT "repo_name"
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES"
    WHERE  "language" ILIKE '%Python%'
    INTERSECT
    SELECT DISTINCT "repo_name"
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES"
    WHERE  "ref" = 'refs/heads/master'
      AND  "path" ILIKE '%.py'
),
licensed AS (                   -- repos with an approved OSS licence
    SELECT DISTINCT "repo_name"
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES"
    WHERE  LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),
base_repos AS (                 -- intersection of Python + OSS-licensed
    SELECT "repo_name"
    FROM   python_repos
    INTERSECT
    SELECT "repo_name" FROM licensed
),
event_counts AS (               -- April-2022 Issue & Fork totals
    SELECT  f.value:"name"::STRING                     AS "repo_name",
            SUM(CASE WHEN t."type" ILIKE '%Issue%' THEN 1 ELSE 0 END) AS "issues_apr2022",
            SUM(CASE WHEN t."type" = 'ForkEvent'   THEN 1 ELSE 0 END) AS "forks_apr2022"
    FROM    "GITHUB_REPOS_DATE"."YEAR"."_2022" t,
            LATERAL FLATTEN( INPUT => t."repo" ) f
    WHERE   t."created_at" BETWEEN 1648771200000000   -- 2022-04-01 00:00 UTC
                               AND     1651363199000000   -- 2022-04-30 23:59 UTC
    GROUP   BY f.value:"name"::STRING
),
watchers AS (                   -- watcher snapshot
    SELECT "repo_name",
           "watch_count"
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_REPOS"
)
SELECT  br."repo_name",
        COALESCE(w."watch_count",0)          AS "watchers",
        COALESCE(ec."issues_apr2022",0)      AS "issues_apr2022",
        COALESCE(ec."forks_apr2022",0)       AS "forks_apr2022",
        COALESCE(w."watch_count",0)
      + COALESCE(ec."issues_apr2022",0)
      + COALESCE(ec."forks_apr2022",0)       AS "activity_score"
FROM        base_repos      br
LEFT JOIN   watchers        w   ON w."repo_name"  = br."repo_name"
LEFT JOIN   event_counts    ec  ON ec."repo_name" = br."repo_name"
ORDER  BY "activity_score" DESC NULLS LAST
LIMIT 1;