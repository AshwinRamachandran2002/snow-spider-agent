WITH "py_repos" AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE "language" ILIKE '%Python%'
),
"monthly_commits" AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(("committer":"date"::NUMBER) / 1000000)) AS "month",
        COUNT(*) AS "commit_count"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    WHERE "repo_name" IN (SELECT "repo_name" FROM "py_repos")
      AND YEAR(TO_TIMESTAMP(("committer":"date"::NUMBER) / 1000000)) = 2016
    GROUP BY 1
)
SELECT AVG("commit_count") AS "avg_commits_per_month_2016"
FROM "monthly_commits";