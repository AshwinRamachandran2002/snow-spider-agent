SELECT
  FORMAT_DATE('%Y-%m', DATE(creation_date)) AS month,
  SAFE_DIVIDE(
    SUM(CASE WHEN REGEXP_CONTAINS(tags, r'(^|\|)python(\||$)') THEN 1 ELSE 0 END),
    COUNT(1)
  ) AS python_question_proportion
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  creation_date >= '2022-01-01'
  AND creation_date <  '2023-01-01'
GROUP BY
  month
ORDER BY
  month;