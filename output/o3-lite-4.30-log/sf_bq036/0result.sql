WITH monthly AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP(c."author":"time_sec"::INTEGER), 'YYYY-MM') AS "year_month",
        COUNT(*) AS "monthly_commits"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
    JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l
      ON c."repo_name" = l."repo_name"
    WHERE l."language" ILIKE '%Python%'
      AND c."author":"time_sec"::INTEGER BETWEEN 1451606400 AND 1483228799
    GROUP BY "year_month"
)
SELECT ROUND(AVG("monthly_commits"), 4) AS "average_commits_per_month_2016"
FROM monthly;