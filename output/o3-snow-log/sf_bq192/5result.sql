/*  Most active Python repo in April-2022 (watchers + issues + forks)  */
WITH
/*----------------------------------------------------------*/
/* 1. Repos whose license is one of the requested            */
licenses AS (
    SELECT DISTINCT
           "repo_name"                                          -- keep quoted to match table definition
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
    WHERE  LOWER("license") IN ('artistic-2.0','isc','mit','apache-2.0')
),
/*----------------------------------------------------------*/
/* 2. Repos that have at least one *.py file on master       */
python_repos AS (
    SELECT DISTINCT
           "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE  "ref"  = 'refs/heads/master'
      AND  LOWER("path") LIKE '%.py'
),
/*----------------------------------------------------------*/
/* 3. Counts of events in April-2022                         */
event_counts AS (
    SELECT
        evt_repo_name                                                   AS repo_name,

        /* distinct watchers (WatchEvent) */
        COUNT(DISTINCT CASE WHEN "type" = 'WatchEvent'
                            THEN "actor":"id"::STRING END)              AS watchers_cnt,

        /* issue-related events */
        SUM(CASE WHEN "type" IN ('IssuesEvent','IssueCommentEvent')
                 THEN 1 ELSE 0 END)                                    AS issues_cnt,

        /* fork events */
        SUM(CASE WHEN "type" = 'ForkEvent'
                 THEN 1 ELSE 0 END)                                    AS forks_cnt
    FROM (
        SELECT
            "type",
            "actor",
            "repo":"name"::STRING     AS evt_repo_name
        FROM   GITHUB_REPOS_DATE.YEAR._2022
        WHERE  TO_TIMESTAMP("created_at" / 1000000) >= '2022-04-01'
          AND  TO_TIMESTAMP("created_at" / 1000000) <  '2022-05-01'
    ) sub
    GROUP BY evt_repo_name
),
/*----------------------------------------------------------*/
/* 4. Combine everything and compute activity score         */
activity AS (
    SELECT
        ec.repo_name,
        ec.watchers_cnt,
        ec.issues_cnt,
        ec.forks_cnt,
        COALESCE(ec.watchers_cnt,0)
      + COALESCE(ec.issues_cnt ,0)
      + COALESCE(ec.forks_cnt  ,0)                           AS activity_score
    FROM   event_counts  ec
           JOIN licenses      l  ON ec.repo_name = l."repo_name"
           JOIN python_repos  p  ON ec.repo_name = p."repo_name"
)
/*----------------------------------------------------------*/
SELECT
       repo_name,
       activity_score
FROM   activity
ORDER  BY activity_score DESC NULLS LAST
LIMIT  1;