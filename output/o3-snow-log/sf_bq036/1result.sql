WITH python_commits_2016 AS (
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP( (c."author":"date"::NUMBER) / 1000000 )
        ) AS month_start
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS  c
    JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES       l
      ON c."repo_name" = l."repo_name"
    WHERE l."language" ILIKE '%Python%'                                    -- repos containing Python
      AND TO_TIMESTAMP( (c."author":"date"::NUMBER) / 1000000 )            -- commit timestamp
            BETWEEN '2016-01-01'::DATE AND '2016-12-31'::DATE             -- calendar year 2016
)

-- count commits per month, then take the average of those monthly counts
SELECT AVG(month_commit_cnt) AS "avg_commits_per_month_2016"
FROM (
    SELECT month_start,
           COUNT(*) AS month_commit_cnt
    FROM python_commits_2016
    GROUP BY month_start
);