/* most‑active Python repository of April 2022 */
WITH python_repos AS (                      -- repos that have at least one *.py file
    SELECT DISTINCT
           LOWER("repo_name")          AS repo_name_lc
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES"
    WHERE  LOWER("path") LIKE '%.py'
),
licensed_repos AS (                        -- repos whose licence is accepted
    SELECT  pr.repo_name_lc
    FROM    python_repos                         pr
    JOIN    "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES" lic
           ON pr.repo_name_lc = LOWER(lic."repo_name")
    WHERE   LOWER(lic."license") IN ('artistic-2.0','isc','mit','apache-2.0')
),
event_counts AS (                           -- watch / issue / fork counts for Apr‑2022
    SELECT
        LOWER( COALESCE(ev."repo":"full_name"::STRING,
                        ev."repo":"name"::STRING) )      AS repo_name_lc,
        COUNT(DISTINCT
              IFF(ev."type" = 'WatchEvent',
                  ev."actor":"id"::STRING,
                  NULL))                                AS watch_cnt,
        SUM( IFF(ev."type" = 'IssuesEvent', 1, 0) )     AS issue_cnt,
        SUM( IFF(ev."type" = 'ForkEvent'  , 1, 0) )     AS fork_cnt
    FROM   "GITHUB_REPOS_DATE"."YEAR"."_2022" ev
    WHERE  TO_DATE( TO_TIMESTAMP_LTZ(ev."created_at" / 1000000) )
           BETWEEN '2022-04-01' AND '2022-04-30'
    GROUP  BY  repo_name_lc
),
combined AS (
    SELECT
        l.repo_name_lc                                 AS repo_name,
        e.watch_cnt,
        e.issue_cnt,
        e.fork_cnt,
        (e.watch_cnt + e.issue_cnt + e.fork_cnt)       AS activity_score
    FROM   licensed_repos l
    JOIN   event_counts   e
           ON l.repo_name_lc = e.repo_name_lc
)
SELECT
       repo_name,
       activity_score
FROM   combined
ORDER  BY activity_score DESC NULLS LAST,
          repo_name
LIMIT  1;