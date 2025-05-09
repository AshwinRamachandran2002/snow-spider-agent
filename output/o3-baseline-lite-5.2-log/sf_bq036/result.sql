/* average number of commits per month in 2016
   for repositories that contain any Python code */
WITH python_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER(CAST("language" AS STRING)) LIKE '%python%'
),
commits_2016 AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP(
                COALESCE(
                    ("committer":"time_sec")::INTEGER,
                    ("author":"time_sec")::INTEGER
                )
            )
        ) AS month_start
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    WHERE "repo_name" IN (SELECT "repo_name" FROM python_repos)
      AND YEAR(
            TO_TIMESTAMP(
                COALESCE(
                    ("committer":"time_sec")::INTEGER,
                    ("author":"time_sec")::INTEGER
                )
            )
          ) = 2016
)
SELECT
    COUNT(*) / 12.0 AS "avg_commits_per_month_2016"
FROM commits_2016;