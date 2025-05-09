/*  Most‑active Python repo (April‑2022) with acceptable OSS licence         */
WITH
/* --------------------------------------------------------------------- */
license_repos AS (          -- repos with one of the required licences
    SELECT  "repo_name" AS repo_name
    FROM    GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE   LOWER("license") IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')
),
/* --------------------------------------------------------------------- */
python_repos AS (           -- repos that have at least one *.py on master
    SELECT  DISTINCT "repo_name" AS repo_name
    FROM    GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE   "ref"  = 'refs/heads/master'
      AND   LOWER("path") LIKE '%.py'
),
/* --------------------------------------------------------------------- */
watchers AS (               -- static watcher count snapshot
    SELECT  "repo_name" AS repo_name,
            COALESCE("watch_count", 0) AS watch_count
    FROM    GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS
),
/* --------------------------------------------------------------------- */
forks_2022_apr AS (         -- forks that happened in April‑2022
    SELECT  "repo":"full_name"::STRING          AS repo_name,
            COUNT(*)                           AS fork_cnt
    FROM    GITHUB_REPOS_DATE.YEAR._2022
    WHERE   "type" = 'ForkEvent'
      AND   TO_TIMESTAMP_LTZ("created_at" / 1000000)
            BETWEEN '2022-04-01' AND '2022-04-30 23:59:59'
    GROUP BY repo_name
),
/* --------------------------------------------------------------------- */
issues_2022_apr AS (        -- issues opened/closed in April‑2022
    SELECT  "repo":"full_name"::STRING          AS repo_name,
            COUNT(*)                           AS issue_cnt
    FROM    GITHUB_REPOS_DATE.YEAR._2022
    WHERE   "type" = 'IssuesEvent'
      AND   TO_TIMESTAMP_LTZ("created_at" / 1000000)
            BETWEEN '2022-04-01' AND '2022-04-30 23:59:59'
    GROUP BY repo_name
)
/* ===================================================================== */
SELECT      core.repo_name                                    AS "REPO_NAME",
            COALESCE(w.watch_count, 0)                        AS "WATCHES",
            COALESCE(f.fork_cnt,   0)                         AS "FORKS",
            COALESCE(i.issue_cnt,  0)                         AS "ISSUES",
            COALESCE(w.watch_count,0)
          + COALESCE(f.fork_cnt,  0)
          + COALESCE(i.issue_cnt, 0)                          AS "ACTIVITY_SCORE"
FROM       (SELECT lr.repo_name
            FROM   license_repos  lr
            JOIN   python_repos   pr  ON pr.repo_name = lr.repo_name) core
LEFT JOIN   watchers        w  ON w.repo_name = core.repo_name
LEFT JOIN   forks_2022_apr  f  ON f.repo_name = core.repo_name
LEFT JOIN   issues_2022_apr i  ON i.repo_name = core.repo_name
ORDER BY    "ACTIVITY_SCORE" DESC NULLS LAST,
            core.repo_name
LIMIT 1;