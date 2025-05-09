/* repository with an approved (non-NULL) license that had the
   highest forks + open-issues + watchers total during April 2022 */
WITH april22 AS (
    SELECT
        "repo":"name"::STRING                                           AS "REPO_NAME",
        (   MAX(COALESCE("repo":"forks_count",0)::INT)
          + MAX(COALESCE("repo":"open_issues_count",0)::INT)
          + MAX(COALESCE("repo":"watchers_count",0)::INT) )             AS "TOTAL_ACTIVITY"
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE TO_TIMESTAMP("created_at" / 1000000) >= '2022-04-01'
      AND TO_TIMESTAMP("created_at" / 1000000) <  '2022-05-01'
    GROUP BY 1
)
SELECT  a."REPO_NAME",
        a."TOTAL_ACTIVITY"
FROM    april22 AS a
JOIN    GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES AS l
          ON l."repo_name" = a."REPO_NAME"
WHERE   l."license" IS NOT NULL
ORDER BY a."TOTAL_ACTIVITY" DESC NULLS LAST
LIMIT 1;