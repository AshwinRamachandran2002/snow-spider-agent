WITH python_repos AS (
    -- repositories that include Python code
    SELECT DISTINCT l."repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
         LATERAL FLATTEN(input => l."language") f
    WHERE LOWER(f.value:"name"::STRING) = 'python'
),
commits_2016 AS (
    -- commits in calendar year 2016 from those repositories
    SELECT
        MONTH( TO_TIMESTAMP_LTZ( (c."author":"date"::INTEGER) / 1000000 ) ) AS "month",
        c."commit"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" c
    JOIN python_repos p
      ON c."repo_name" = p."repo_name"
    WHERE YEAR( TO_TIMESTAMP_LTZ( (c."author":"date"::INTEGER) / 1000000 ) ) = 2016
),
monthly_totals AS (
    -- number of commits per month
    SELECT "month", COUNT("commit") AS "commit_count"
    FROM commits_2016
    GROUP BY "month"
)
-- average commits per month across 2016
SELECT AVG("commit_count") AS "avg_commits_per_month_2016"
FROM monthly_totals;