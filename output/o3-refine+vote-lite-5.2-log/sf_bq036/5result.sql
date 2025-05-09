WITH python_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER(CAST("language" AS STRING)) LIKE '%python%'
),
commits_2016 AS (
    SELECT
        TO_TIMESTAMP(CAST(sc."author":"time_sec" AS NUMBER)) AS commit_ts
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS sc
    JOIN python_repos pr
      ON sc."repo_name" = pr."repo_name"
    WHERE sc."author":"time_sec" IS NOT NULL
      AND EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(sc."author":"time_sec" AS NUMBER))) = 2016
)
SELECT
    ROUND(COUNT(*) / 12.0, 4) AS "AVG_COMMITS_PER_MONTH_2016"
FROM commits_2016;