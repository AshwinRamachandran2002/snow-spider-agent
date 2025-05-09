WITH python_repos AS (
    -- repositories whose recorded language list includes “Python”
    SELECT DISTINCT "repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"
    WHERE LOWER("language") LIKE '%python%'
),
commits_2016 AS (
    -- commits from those repos authored in 2016
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP(("author":"date"::NUMBER) / 1000000)
        )                              AS "month_2016",
        "commit"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS"
    WHERE "repo_name" IN (SELECT "repo_name" FROM python_repos)
      AND EXTRACT(
            year
            FROM TO_TIMESTAMP(("author":"date"::NUMBER) / 1000000)
          ) = 2016
),
monthly_counts AS (
    -- number of commits each month
    SELECT "month_2016", COUNT(*) AS "commit_cnt"
    FROM commits_2016
    GROUP BY "month_2016"
)
-- average monthly commits in 2016 for Python repositories
SELECT AVG("commit_cnt") AS "avg_commits_per_month_2016"
FROM monthly_counts;