WITH python_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE "language":"Python" IS NOT NULL
),
commits_2016 AS (
    SELECT COUNT(*) AS commits_2016
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    WHERE "repo_name" IN (SELECT "repo_name" FROM python_repos)
      AND EXTRACT(year FROM TO_TIMESTAMP_NTZ("committer":"time_sec")) = 2016
)
SELECT commits_2016 / 12.0 AS "AVG_COMMITS_PER_MONTH_2016"
FROM commits_2016;