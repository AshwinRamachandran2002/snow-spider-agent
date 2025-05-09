SELECT 
    ROUND(AVG("monthly_commit_count"), 4) AS average_commits_per_month_2016
FROM (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(c."author":"date"::NUMBER / 1000000)) AS "month_2016",
        COUNT(*)                                                              AS "monthly_commit_count"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS  AS c
    JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES       AS l
      ON c."repo_name" = l."repo_name"
    WHERE CAST(l."language" AS STRING) ILIKE '%Python%'
      AND TO_TIMESTAMP(c."author":"date"::NUMBER / 1000000) >= '2016-01-01'
      AND TO_TIMESTAMP(c."author":"date"::NUMBER / 1000000) <  '2017-01-01'
    GROUP BY DATE_TRUNC('month', TO_TIMESTAMP(c."author":"date"::NUMBER / 1000000))
);