WITH monthly AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(creation_date))               AS month,
    COUNT(*)                                                AS total_questions,
    SUM(
      CASE
        WHEN REGEXP_CONTAINS(tags, r'(^|\|)python(\||$)')   THEN 1
        ELSE 0
      END
    )                                                      AS python_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE DATE(creation_date) BETWEEN '2022-01-01' AND '2022-12-31'
  GROUP BY month
)

SELECT
  month,
  total_questions,
  python_questions,
  SAFE_DIVIDE(python_questions, total_questions) AS proportion
FROM monthly
ORDER BY month;