/* Average number of commits per month in 2016 for repos that include Python */
WITH python_repos AS (
    SELECT DISTINCT "repo_name"
    FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE  "language"::STRING ILIKE '%Python%'
),
commits_2016 AS (
    SELECT DATE_TRUNC('month',
                      TO_TIMESTAMP(c."author"::VARIANT:"time_sec")) AS "commit_month",
           COUNT(*) AS "monthly_commits"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS  c
    JOIN   python_repos                               p
           USING ("repo_name")
    WHERE  TO_TIMESTAMP(c."author"::VARIANT:"time_sec")
              BETWEEN '2016-01-01' AND '2016-12-31 23:59:59'
    GROUP  BY 1
)
SELECT AVG("monthly_commits") AS "avg_commits_per_month_2016"
FROM   commits_2016;