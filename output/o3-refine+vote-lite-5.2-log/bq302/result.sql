SELECT
  FORMAT_DATE('%Y-%m', month)           AS year_month,
  SAFE_DIVIDE(python_questions, total_questions) AS python_proportion
FROM (
  SELECT
    DATE_TRUNC(DATE(creation_date), MONTH)                                     AS month,
    COUNTIF(REGEXP_CONTAINS(tags, r'(^|\|)python(\||$)')) AS python_questions,
    COUNT(*)                                                 AS total_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
  GROUP BY month
)
ORDER BY month;