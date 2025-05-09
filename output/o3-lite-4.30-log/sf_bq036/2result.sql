WITH python_repos AS (
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE CAST("language" AS STRING) ILIKE '%Python%'
),
commits_2016 AS (
    SELECT
        TO_CHAR(
            DATEADD(
                second,
                ("author":"date"::number) / 1000000,
                '1970-01-01'
            ),
            'YYYY-MM'
        ) AS month_label
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    WHERE "repo_name" IN (SELECT "repo_name" FROM python_repos)
      AND ("author":"date"::number) BETWEEN 1451606400000000 AND 1483228799000000
)
SELECT
    ROUND(AVG(month_commit_count), 4) AS average_commits_per_month_2016
FROM (
    SELECT
        month_label,
        COUNT(*) AS month_commit_count
    FROM commits_2016
    GROUP BY month_label
) t;