WITH watch_cte AS (   -- Watch events during April-2022
    SELECT
        "repo":"name"::STRING AS repo_name,
        COUNT(*)              AS watches
    FROM   GITHUB_REPOS_DATE.YEAR._2022
    WHERE  "type" = 'WatchEvent'
      AND  "created_at" BETWEEN 1648771200000000  -- 2022-04-01 00:00:00 UTC
                           AND 1651363200000000  -- 2022-05-01 00:00:00 UTC
    GROUP  BY repo_name
),
issue_cte AS (         -- IssuesEvent + IssueCommentEvent
    SELECT
        "repo":"name"::STRING AS repo_name,
        COUNT(*)              AS issues
    FROM   GITHUB_REPOS_DATE.YEAR._2022
    WHERE  "type" IN ('IssuesEvent','IssueCommentEvent')
      AND  "created_at" BETWEEN 1648771200000000 AND 1651363200000000
    GROUP  BY repo_name
),
fork_cte AS (          -- Fork events
    SELECT
        "repo":"name"::STRING AS repo_name,
        COUNT(*)              AS forks
    FROM   GITHUB_REPOS_DATE.YEAR._2022
    WHERE  "type" = 'ForkEvent'
      AND  "created_at" BETWEEN 1648771200000000 AND 1651363200000000
    GROUP  BY repo_name
),
activity AS (          -- combined activity score
    SELECT
        COALESCE(w.repo_name,i.repo_name,f.repo_name)              AS repo_name,
        COALESCE(w.watches,0)+COALESCE(i.issues,0)+COALESCE(f.forks,0) AS activity_score
    FROM watch_cte w
    FULL JOIN issue_cte i ON i.repo_name = w.repo_name
    FULL JOIN fork_cte  f ON f.repo_name  = COALESCE(w.repo_name,i.repo_name)
),
licensed_repos AS (    -- repositories with an approved license
    SELECT LOWER("repo_name") AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE  LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),
python_repos AS (      -- repositories containing at least one *.py file on master
    SELECT DISTINCT LOWER("repo_name") AS repo_name
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE  "ref"  = 'refs/heads/master'
      AND  "path" ILIKE '%.py'
),
qualified AS (         -- only repos that satisfy all three conditions
    SELECT  a.repo_name,
            a.activity_score
    FROM    activity         a
    JOIN    licensed_repos   l ON l.repo_name   = LOWER(a.repo_name)
    JOIN    python_repos     p ON p.repo_name   = LOWER(a.repo_name)
)
SELECT
    repo_name,
    activity_score
FROM   qualified
ORDER  BY activity_score DESC NULLS LAST
LIMIT  1;