WITH python_repos AS (
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE "language":"Python" IS NOT NULL          -- repos that include Python
),
commits_2016 AS (
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP_LTZ(("author":"date")::NUMBER , 6)   -- 6 = micro‑seconds
                  )  AS commit_month
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
    JOIN python_repos p
      ON c."repo_name" = p."repo_name"
    WHERE TO_TIMESTAMP_LTZ((c."author":"date")::NUMBER , 6) 
              BETWEEN '2016-01-01' AND '2016-12-31 23:59:59.999'
),
commits_per_month AS (
    SELECT commit_month, COUNT(*) AS commits
    FROM commits_2016
    GROUP BY commit_month
)
SELECT AVG(commits) AS "AVG_COMMITS_PER_MONTH_2016"
FROM commits_per_month;