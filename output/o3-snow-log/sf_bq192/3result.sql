/* Most-active Python repository in April-2022 with an approved license */
WITH event_counts AS (
    /* Consolidate distinct watchers, issues/comments, and forks */
    SELECT
        repo_name,
        SUM(watcher_cnt) AS watcher_cnt,
        SUM(issue_cnt)   AS issue_cnt,
        SUM(fork_cnt)    AS fork_cnt
    FROM (
        /* Watch events (distinct watchers) */
        SELECT
            "repo":"name"::string                           AS repo_name,
            COUNT(DISTINCT "actor":"id"::string)            AS watcher_cnt,
            0                                               AS issue_cnt,
            0                                               AS fork_cnt
        FROM GITHUB_REPOS_DATE.YEAR."_2022"
        WHERE "type" = 'WatchEvent'
          AND TO_TIMESTAMP("created_at"/1000000) >= '2022-04-01'
          AND TO_TIMESTAMP("created_at"/1000000) <  '2022-05-01'
        GROUP BY "repo":"name"::string

        UNION ALL

        /* Issue and issue-comment events */
        SELECT
            "repo":"name"::string                 AS repo_name,
            0                                      AS watcher_cnt,
            COUNT(*)                               AS issue_cnt,
            0                                      AS fork_cnt
        FROM GITHUB_REPOS_DATE.YEAR."_2022"
        WHERE "type" IN ('IssuesEvent','IssueCommentEvent')
          AND TO_TIMESTAMP("created_at"/1000000) >= '2022-04-01'
          AND TO_TIMESTAMP("created_at"/1000000) <  '2022-05-01'
        GROUP BY "repo":"name"::string

        UNION ALL

        /* Fork events */
        SELECT
            "repo":"name"::string                 AS repo_name,
            0                                      AS watcher_cnt,
            0                                      AS issue_cnt,
            COUNT(*)                               AS fork_cnt
        FROM GITHUB_REPOS_DATE.YEAR."_2022"
        WHERE "type" = 'ForkEvent'
          AND TO_TIMESTAMP("created_at"/1000000) >= '2022-04-01'
          AND TO_TIMESTAMP("created_at"/1000000) <  '2022-05-01'
        GROUP BY "repo":"name"::string
    )
    GROUP BY repo_name
),

/* Repositories that contain at least one *.py file on the master branch */
py_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE LOWER("path") LIKE '%.py'
      AND "ref" = 'refs/heads/master'
),

/* Repositories with one of the approved licenses */
licensed_repos AS (
    SELECT "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE  LOWER("license") IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')
)

/* Final selection: combine filters, compute activity score, and choose top repo */
SELECT
    e.repo_name,
    (e.watcher_cnt + e.issue_cnt + e.fork_cnt) AS activity_score
FROM      event_counts    e
JOIN      py_repos        p ON e.repo_name = p."repo_name"
JOIN      licensed_repos  l ON e.repo_name = l."repo_name"
ORDER BY  activity_score DESC NULLS LAST
LIMIT 1;