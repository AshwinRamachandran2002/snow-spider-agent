/* Average number of commits per month in 2016 for repositories that contain Python code */
SELECT 
  AVG(monthly_cnt) AS "avg_commits_per_month_2016"
FROM (
    SELECT
      DATE_TRUNC('month', TO_TIMESTAMP( ("author":"time_sec")::NUMBER )) AS month,
      COUNT(*) AS monthly_cnt
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS       c
    JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES            l
          ON c."repo_name" = l."repo_name"
    WHERE CAST(l."language" AS STRING) ILIKE '%Python%'               -- repos with Python
      AND YEAR( TO_TIMESTAMP( ("author":"time_sec")::NUMBER )) = 2016 -- commits in 2016
    GROUP BY month
);