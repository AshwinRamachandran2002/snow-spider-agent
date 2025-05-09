WITH python_repos AS (
    SELECT "repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"
    WHERE "language" ILIKE '%Python%'
), commits_2016 AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ( (c."author":"date")::NUMBER / 1000000 )) AS "month"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" c
    JOIN python_repos pr
      ON c."repo_name" = pr."repo_name"
    WHERE YEAR( TO_TIMESTAMP_NTZ( (c."author":"date")::NUMBER / 1000000 ) ) = 2016
)
SELECT AVG("monthly_commits") AS "avg_commits_per_month_2016"
FROM (
    SELECT "month", COUNT(*) AS "monthly_commits"
    FROM commits_2016
    GROUP BY "month"
) t;