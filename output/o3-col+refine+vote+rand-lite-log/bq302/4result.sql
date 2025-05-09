-- Monthly proportion of Stack Overflow questions tagged with 'python' in 2022
WITH monthly_counts AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(creation_date)) AS month_2022,
    COUNT(*) AS total_questions,
    COUNTIF(REGEXP_CONTAINS(tags, r'(^|\|)python(\||$)')) AS python_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date BETWEEN '2022-01-01' AND '2022-12-31'
  GROUP BY month_2022
)
SELECT
  month_2022,
  python_questions,
  total_questions,
  ROUND(SAFE_DIVIDE(python_questions, total_questions), 4) AS proportion_python
FROM monthly_counts
ORDER BY month_2022;