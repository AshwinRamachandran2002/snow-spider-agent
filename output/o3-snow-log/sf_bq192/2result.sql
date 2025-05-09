WITH licensed_py_repos AS (   -- repos with accepted licence and .py files on master
    SELECT DISTINCT l."repo_name" AS "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES     l
    JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES f
           ON l."repo_name" = f."repo_name"
    WHERE  LOWER(l."license") IN ('artistic-2.0','isc','mit','apache-2.0')
      AND  f."ref"  = 'refs/heads/master'
      AND  LOWER(f."path") LIKE '%.py'
),  --------------------------------------------------------------------
watchers AS (                    -- watcher counts
    SELECT
        r."repo_name"           AS "repo_name",
        r."watch_count"::NUMBER AS watch_cnt
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS r
),  --------------------------------------------------------------------
issues_apr22 AS (                -- issue activity in April-2022
    SELECT
        t."repo":name::STRING   AS "repo_name",
        COUNT(*)                AS issue_cnt
    FROM   GITHUB_REPOS_DATE.YEAR."_2022" t
    WHERE  t."type" IN ('IssuesEvent','IssueCommentEvent')
      AND  TO_TIMESTAMP(t."created_at"/1000000)
           BETWEEN '2022-04-01' AND '2022-05-01'
    GROUP BY "repo_name"
),  --------------------------------------------------------------------
forks_apr22 AS (                 -- forks in April-2022
    SELECT
        t."repo":name::STRING   AS "repo_name",
        COUNT(*)                AS fork_cnt
    FROM   GITHUB_REPOS_DATE.YEAR."_2022" t
    WHERE  t."type" = 'ForkEvent'
      AND  TO_TIMESTAMP(t."created_at"/1000000)
           BETWEEN '2022-04-01' AND '2022-05-01'
    GROUP BY "repo_name"
)   --------------------------------------------------------------------
SELECT
    r."repo_name",
    COALESCE(w.watch_cnt, 0)                      AS watch_count,
    COALESCE(i.issue_cnt, 0)                      AS issue_count,
    COALESCE(f.fork_cnt , 0)                      AS fork_count,
    COALESCE(w.watch_cnt, 0)
      + COALESCE(i.issue_cnt, 0)
      + COALESCE(f.fork_cnt , 0)                  AS activity_score
FROM   licensed_py_repos r
LEFT   JOIN watchers     w USING ("repo_name")
LEFT   JOIN issues_apr22 i USING ("repo_name")
LEFT   JOIN forks_apr22  f USING ("repo_name")
ORDER  BY activity_score DESC NULLS LAST
LIMIT  1;