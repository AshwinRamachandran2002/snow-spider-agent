WITH months AS (
  SELECT
    DATE '2022-01-01' + INTERVAL seq MONTH AS month_start
  FROM UNNEST(GENERATE_ARRAY(0, 11)) AS seq
),
stats AS (
  SELECT
    DATE_TRUNC(DATE(creation_date), MONTH) AS month_start,
    COUNT(*) AS total_questions,
    COUNTIF('python' IN UNNEST(SPLIT(LOWER(tags), '|'))) AS python_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
  GROUP BY month_start
)
SELECT
  FORMAT_DATE('%b-%Y', months.month_start) AS Month,
  ROUND(COALESCE(stats.python_questions / stats.total_questions, 0), 4) AS Proportion
FROM months
LEFT JOIN stats
ON months.month_start = stats.month_start
ORDER BY months.month_start