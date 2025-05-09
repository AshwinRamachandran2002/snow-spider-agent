-- Monthly proportion of Stack Overflow questions tagged with 'python' (2022)
WITH questions_2022 AS (
  SELECT
    DATE_TRUNC(DATE(creation_date), MONTH) AS month_start,
    LOWER(IFNULL(tags, ''))               AS tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
)

SELECT
  FORMAT_DATE('%Y-%m', month_start)                                   AS month,
  COUNTIF(REGEXP_CONTAINS(tags, r'(^|[|])python([|]|$)'))             AS python_questions,
  COUNT(*)                                                            AS total_questions,
  SAFE_DIVIDE(
    COUNTIF(REGEXP_CONTAINS(tags, r'(^|[|])python([|]|$)')),
    COUNT(*)
  )                                                                   AS proportion
FROM questions_2022
GROUP BY month_start
ORDER BY month_start;