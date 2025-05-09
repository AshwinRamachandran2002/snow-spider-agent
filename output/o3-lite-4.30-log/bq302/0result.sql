SELECT
  FORMAT_DATE('%Y-%m', month_start)        AS month,
  ROUND(SAFE_DIVIDE(python_q, total_q), 4) AS python_question_proportion
FROM (
  SELECT
    DATE_TRUNC(DATE(creation_date), MONTH)                      AS month_start,
    COUNT(*)                                                    AS total_q,
    COUNTIF(REGEXP_CONTAINS(tags, r'(^|[|])python([|]|$)'))     AS python_q
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
  GROUP BY month_start
)
ORDER BY month_start;