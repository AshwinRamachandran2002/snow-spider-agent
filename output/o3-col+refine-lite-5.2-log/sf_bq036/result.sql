WITH python_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES,
         LATERAL FLATTEN(input => "language") lang
    WHERE lang.value:"name"::STRING ILIKE '%python%'
),
monthly_commits AS (
    SELECT
        DATE_TRUNC('month', TO_DATE(TO_TIMESTAMP(sc."author":time_sec::NUMBER))) AS "commit_month",
        COUNT(*) AS "commit_count"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS sc
    JOIN python_repos pr
      ON sc."repo_name" = pr."repo_name"
    WHERE YEAR(TO_DATE(TO_TIMESTAMP(sc."author":time_sec::NUMBER))) = 2016
    GROUP BY 1
)
SELECT
    AVG("commit_count") AS "avg_commits_per_month_2016_python"
FROM monthly_commits;