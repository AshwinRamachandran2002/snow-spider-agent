WITH python_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE "language":"Python" IS NOT NULL
),
commits_2016 AS (
    SELECT 1
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
    JOIN python_repos p
      ON c."repo_name" = p."repo_name"
    WHERE TO_TIMESTAMP( (c."author":"time_sec")::NUMBER ) >= '2016-01-01'::TIMESTAMP
      AND TO_TIMESTAMP( (c."author":"time_sec")::NUMBER ) <  '2017-01-01'::TIMESTAMP
)
SELECT ROUND(COUNT(*) / 12.0, 4) AS "avg_commits_per_month_2016"
FROM commits_2016;