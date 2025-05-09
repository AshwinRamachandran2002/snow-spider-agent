WITH "PY_REPOS" AS (
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE "language":"Python" IS NOT NULL
),
"COMMITS_2016" AS (
    SELECT 
        TO_CHAR(TO_TIMESTAMP(("author":"time_sec")::NUMBER), 'YYYY-MM') AS "month"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS AS c
    JOIN "PY_REPOS" AS p
      ON c."repo_name" = p."repo_name"
    WHERE TO_TIMESTAMP(("author":"time_sec")::NUMBER) >= '2016-01-01'
      AND TO_TIMESTAMP(("author":"time_sec")::NUMBER) <  '2017-01-01'
),
"MONTHLY_COUNTS" AS (
    SELECT "month",
           COUNT(*) AS "commit_count"
    FROM "COMMITS_2016"
    GROUP BY "month"
)
SELECT AVG("commit_count") AS "avg_commits_per_month_2016"
FROM "MONTHLY_COUNTS";