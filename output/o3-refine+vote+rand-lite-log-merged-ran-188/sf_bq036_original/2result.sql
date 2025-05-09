WITH python_repos AS (   -- repositories that have Python listed among their languages
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER("language"::STRING) LIKE '%python%'
),
commits_2016 AS (       -- commits in 2016 belonging to those repositories
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP(("author":"date")::NUMBER / 1000000)
        ) AS month_start
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS AS c
    JOIN python_repos          AS p
      ON c."repo_name" = p."repo_name"
    WHERE EXTRACT(year FROM TO_TIMESTAMP(("author":"date")::NUMBER / 1000000)) = 2016
),
monthly_counts AS (     -- number of commits per month
    SELECT
        month_start,
        COUNT(*) AS commit_count
    FROM commits_2016
    GROUP BY month_start
)
SELECT AVG(commit_count) AS avg_commits_per_month_2016
FROM   monthly_counts;