-- Monthly proportion of Stack Overflow questions tagged with “python” in 2022
WITH monthly AS (
  SELECT
    EXTRACT(MONTH FROM creation_date)                     AS month,
    COUNT(*)                                              AS total_questions,
    COUNTIF(REGEXP_CONTAINS(tags, r'(^|[|])python([|]|$)')) AS python_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
  GROUP BY month
)
SELECT
  FORMAT_DATE('%B', DATE(2022, month, 1))                AS month_name,
  total_questions,
  python_questions,
  ROUND(python_questions / total_questions, 4)           AS python_proportion
FROM monthly
ORDER BY month;