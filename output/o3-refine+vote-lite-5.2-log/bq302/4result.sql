-- Monthly proportion of Stack Overflow questions tagged with “python” in 2022
WITH month_counts AS (
  SELECT
    FORMAT_TIMESTAMP('%Y-%m', creation_date)                AS month,
    COUNT(*)                                                AS total_questions,
    SUM(
      -- true when “python” appears as an individual tag
      IF(
        REGEXP_CONTAINS(LOWER(tags), r'(^|[|])python([|]|$)'),
        1, 0)
    )                                                      AS python_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
  GROUP BY month
)

SELECT
  month,
  python_questions,
  total_questions,
  ROUND(python_questions / total_questions, 4) AS proportion_python
FROM month_counts
ORDER BY month;