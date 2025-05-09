WITH monthly_questions AS (
  SELECT
    DATE_TRUNC(DATE(creation_date), MONTH)           AS month,
    REGEXP_CONTAINS(tags, r'(^|\|)python(\||$)')     AS is_python
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
)

SELECT
  month,
  COUNTIF(is_python)                           AS python_questions,
  COUNT(*)                                     AS total_questions,
  SAFE_DIVIDE(COUNTIF(is_python), COUNT(*))    AS proportion_python
FROM monthly_questions
GROUP BY month
ORDER BY month;