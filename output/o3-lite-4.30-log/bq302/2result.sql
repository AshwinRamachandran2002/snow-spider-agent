SELECT
  FORMAT_DATE('%Y-%m', DATE(creation_date)) AS month,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(REGEXP_CONTAINS(IFNULL(tags, ''), r'(^|\|)python(\||$)')),
      COUNT(*)
    ),
    4
  ) AS python_question_proportion
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE EXTRACT(YEAR FROM creation_date) = 2022
GROUP BY month
ORDER BY month;