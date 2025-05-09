SELECT
  FORMAT_DATE('%Y-%m', DATE(creation_date))                                    AS month,
  COUNTIF(REGEXP_CONTAINS(tags, r'(^|[|])python([|]|$)'))                      AS python_questions,
  COUNT(*)                                                                     AS total_questions,
  SAFE_DIVIDE(
    COUNTIF(REGEXP_CONTAINS(tags, r'(^|[|])python([|]|$)')),
    COUNT(*)
  )                                                                            AS python_share
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE EXTRACT(YEAR FROM creation_date) = 2022
GROUP BY month
ORDER BY month;