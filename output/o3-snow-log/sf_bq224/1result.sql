WITH licensed_repos AS (                     -- repos that have a (non-null) license
    SELECT DISTINCT "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE  "license" IS NOT NULL
),

events_in_apr22 AS (                         -- events that occurred during April 2022
    SELECT
        "repo":"name"::STRING  AS repo_name,
        PARSE_JSON("payload")  AS pl
    FROM   GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE  "created_at" BETWEEN 1648771200000000     -- 2022-04-01 00:00:00 UTC
                           AND     1651363199000000  -- 2022-04-30 23:59:59 UTC
),

repo_counts AS (                             -- fork / issue / watch numbers found in each event
    SELECT
        repo_name,

        COALESCE( pl:"repository":"forks_count",
                  pl:"repo":"forks_count",
                  pl:"base":"repo":"forks_count",
                  pl:"head":"repo":"forks_count" )::NUMBER                      AS forks_cnt,

        COALESCE( pl:"repository":"open_issues_count",
                  pl:"repo":"open_issues_count",
                  pl:"base":"repo":"open_issues_count",
                  pl:"head":"repo":"open_issues_count" )::NUMBER                AS issues_cnt,

        COALESCE( pl:"repository":"watchers_count",
                  pl:"repo":"watchers_count",
                  pl:"base":"repo":"watchers_count",
                  pl:"head":"repo":"watchers_count" )::NUMBER                   AS watch_cnt
    FROM events_in_apr22
),

totals AS (                                  -- highest observed (forks+issues+watches) per repo
    SELECT
        repo_name,
        MAX( COALESCE(forks_cnt,0)
           + COALESCE(issues_cnt,0)
           + COALESCE(watch_cnt,0) )                           AS combined_total
    FROM   repo_counts
    GROUP BY repo_name
)

SELECT
    t.repo_name,
    t.combined_total
FROM   totals           t
JOIN   licensed_repos   l  ON t.repo_name = l."repo_name"
ORDER  BY t.combined_total DESC NULLS LAST
LIMIT  1;