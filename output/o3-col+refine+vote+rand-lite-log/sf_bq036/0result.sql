WITH python_repos AS (
    -- Repositories that contain Python code
    SELECT "repo_name"
    FROM   "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"
    WHERE  CAST("language" AS STRING) ILIKE '%python%'
),
commits_2016 AS (
    -- All commits in 2016 for those Python repositories
    SELECT MONTH(TO_TIMESTAMP_NTZ(("author":"date")::NUMBER / 1000000)) AS "month"
    FROM   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" AS c
    JOIN   python_repos                           AS p
           ON c."repo_name" = p."repo_name"
    WHERE  YEAR(TO_TIMESTAMP_NTZ(("author":"date")::NUMBER / 1000000)) = 2016
),
monthly_totals AS (
    -- Ensure every month (1-12) is represented; fill missing months with zero commits
    SELECT m."month",
           COUNT(c."month") AS "commit_cnt"
    FROM   (SELECT seq4() + 1 AS "month" FROM TABLE(GENERATOR(ROWCOUNT => 12))) AS m
    LEFT   JOIN commits_2016            AS c
           ON m."month" = c."month"
    GROUP  BY m."month"
)
-- Average number of commits per month in 2016
SELECT AVG("commit_cnt") AS "avg_commits_per_month_2016"
FROM   monthly_totals;