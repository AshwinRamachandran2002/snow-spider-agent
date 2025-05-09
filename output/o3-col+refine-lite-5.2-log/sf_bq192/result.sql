/* Most‑active Python repository in April 2022 */
WITH issue_events AS (           -- issue‑related events
    SELECT  "repo":"name"::STRING AS repo_name,
            COUNT(*)              AS issues_events
    FROM    GITHUB_REPOS_DATE.YEAR._2022
    WHERE   "type" ILIKE '%Issue%'
      AND  (
              "created_at" BETWEEN 1648771200000000 AND 1651363199000000   -- µs
           OR "created_at" BETWEEN 1648771200000    AND 1651363199000      -- ms
           )
    GROUP BY repo_name
),
fork_events AS (                 -- fork events
    SELECT  "repo":"name"::STRING AS repo_name,
            COUNT(*)              AS fork_events
    FROM    GITHUB_REPOS_DATE.YEAR._2022
    WHERE   "type" = 'ForkEvent'
      AND  (
              "created_at" BETWEEN 1648771200000000 AND 1651363199000000
           OR "created_at" BETWEEN 1648771200000    AND 1651363199000
           )
    GROUP BY repo_name
),
base AS (                        -- repos passing all filters
    SELECT  sr."repo_name"                   AS repo_name,
            COALESCE(sr."watch_count", 0)    AS watch_count,
            COALESCE(ie.issues_events, 0)    AS issues_events,
            COALESCE(fe.fork_events, 0)      AS fork_events
    FROM    GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS   sr
    LEFT    JOIN issue_events  ie ON sr."repo_name" = ie.repo_name
    LEFT    JOIN fork_events   fe ON sr."repo_name" = fe.repo_name
    JOIN    GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES   sf
           ON  sr."repo_name" = sf."repo_name"
          AND sf."path" ILIKE '%.py'
          AND sf."ref"  = 'refs/heads/master'
    JOIN    GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES       li
           ON  sr."repo_name" = li."repo_name"
          AND li."license" IN ('artistic-2.0','isc','mit','apache-2.0')
)
SELECT  repo_name,
        watch_count + issues_events*10 + fork_events*5 AS activity_score
FROM   (
        SELECT  repo_name,
                watch_count,
                issues_events,
                fork_events,
                ROW_NUMBER() OVER (
                    ORDER BY (watch_count + issues_events*10 + fork_events*5) DESC
                ) AS rn
        FROM    base
       ) t
WHERE  rn = 1;