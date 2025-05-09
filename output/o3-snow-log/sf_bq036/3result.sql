/* Average number of commits per month in 2016 for repositories that contain Python code */
WITH python_repos AS (
    /* 1.  Repositories listing Python among their languages */
    SELECT DISTINCT
           l."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
    WHERE LOWER(f.value:"name"::STRING) = 'python'
),
commits_2016 AS (
    /* 2.  All 2016 commits from those Python repositories */
    SELECT
        c."repo_name",
        TO_CHAR(
            TO_TIMESTAMP_LTZ(c."author":"date"::NUMBER / 1000000),
            'YYYY-MM'
        ) AS "yyyy_mm"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
    JOIN python_repos pr
      ON c."repo_name" = pr."repo_name"
    WHERE YEAR(TO_TIMESTAMP_LTZ(c."author":"date"::NUMBER / 1000000)) = 2016
),
monthly_totals AS (
    /* 3.  Commit counts per calendar month */
    SELECT
        "yyyy_mm",
        COUNT(*) AS "monthly_commits"
    FROM commits_2016
    GROUP BY "yyyy_mm"
)
SELECT
    AVG("monthly_commits") AS "avg_commits_per_month_2016"
FROM monthly_totals;