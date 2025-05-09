WITH python_repos AS (
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE "language" ILIKE '%Python%'
),
commits_2016 AS (
    SELECT
        TO_CHAR(
            TO_TIMESTAMP_NTZ( ("author":"date")::NUMBER / 1000000 ),
            'YYYY-MM'
        ) AS "year_month"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    WHERE "repo_name" IN (SELECT "repo_name" FROM python_repos)
      AND EXTRACT(
            YEAR FROM TO_TIMESTAMP_NTZ( ("author":"date")::NUMBER / 1000000 )
          ) = 2016
),
monthly_counts AS (
    SELECT
        "year_month",
        COUNT(*) AS "monthly_cnt"
    FROM commits_2016
    GROUP BY "year_month"
)
SELECT
    AVG("monthly_cnt") AS "avg_commits_per_month_2016"
FROM monthly_counts;