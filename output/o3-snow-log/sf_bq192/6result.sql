/* ---------------------------------------------------------------
   Most-active Python repository in April 2022
   (score = watchers + issue events + forks)
   ---------------------------------------------------------------- */
WITH watchers_cte AS (          /* distinct users that watched a repo in Apr-2022 */
    SELECT
        "repo":"name"::TEXT                           AS repo_name,
        COUNT(DISTINCT "actor":"id"::TEXT)            AS watch_cnt
    FROM   GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE  "type" = 'WatchEvent'
      AND  CAST(TO_TIMESTAMP("created_at" / 1000000) AS DATE)
           BETWEEN '2022-04-01' AND '2022-04-30'
    GROUP  BY "repo":"name"
),
issues_cte AS (                /* issue and issue-comment events */
    SELECT
        "repo":"name"::TEXT   AS repo_name,
        COUNT(*)              AS issue_cnt
    FROM   GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE  "type" IN ('IssuesEvent', 'IssueCommentEvent')
      AND  CAST(TO_TIMESTAMP("created_at" / 1000000) AS DATE)
           BETWEEN '2022-04-01' AND '2022-04-30'
    GROUP  BY "repo":"name"
),
forks_cte AS (                 /* forks in Apr-2022 */
    SELECT
        "repo":"name"::TEXT   AS repo_name,
        COUNT(*)              AS fork_cnt
    FROM   GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE  "type" = 'ForkEvent'
      AND  CAST(TO_TIMESTAMP("created_at" / 1000000) AS DATE)
           BETWEEN '2022-04-01' AND '2022-04-30'
    GROUP  BY "repo":"name"
),
python_repos AS (              /* repos that have .py files on master */
    SELECT DISTINCT "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE  "path" ILIKE '%.py'
      AND  "ref" = 'refs/heads/master'
),
licensed_repos AS (            /* repos with accepted open-source licenses */
    SELECT "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE  "license" IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')
),
activity AS (                  /* merge counts and compute activity score */
    SELECT
        pr."repo_name",
        COALESCE(w.watch_cnt , 0) AS watch_cnt,
        COALESCE(i.issue_cnt , 0) AS issue_cnt,
        COALESCE(f.fork_cnt  , 0) AS fork_cnt,
        COALESCE(w.watch_cnt , 0)
      + COALESCE(i.issue_cnt , 0)
      + COALESCE(f.fork_cnt  , 0) AS activity_score
    FROM   python_repos     pr
    JOIN   licensed_repos   lr ON pr."repo_name" = lr."repo_name"
    LEFT   JOIN watchers_cte w  ON pr."repo_name" = w.repo_name
    LEFT   JOIN issues_cte   i  ON pr."repo_name" = i.repo_name
    LEFT   JOIN forks_cte    f  ON pr."repo_name" = f.repo_name
)
SELECT
    "repo_name"      AS most_active_repo,
    activity_score   AS total_activity
FROM   activity
ORDER  BY activity_score DESC NULLS LAST
LIMIT  1;