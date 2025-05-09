WITH python_repos AS (   -- repos that include Python code
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE "language"::string ILIKE '%Python%'
),
commits_with_ts AS (     -- commits from those repos with a real timestamp
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP( ( "author":"date" )::number / 1000000 )
                  )       AS commit_month
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS  sc
    JOIN python_repos                               pr
      ON sc."repo_name" = pr."repo_name"
),
monthly_2016 AS (        -- commits per month in 2016
    SELECT
        commit_month,
        COUNT(*) AS commits_in_month
    FROM commits_with_ts
    WHERE EXTRACT(year FROM commit_month) = 2016
    GROUP BY commit_month
)
SELECT AVG(commits_in_month) AS avg_commits_per_month_2016
FROM   monthly_2016;