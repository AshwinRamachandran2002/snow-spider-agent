WITH monthly_counts AS (
  SELECT
    DATE_TRUNC(DATE(creation_date), MONTH) AS month_start,
    COUNT(*) AS total_questions,
    SUM(
      CASE
        WHEN REGEXP_CONTAINS(tags, r'(^|\|)python(\||$)') THEN 1
        ELSE 0
      END
    ) AS python_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date >= '2022-01-01'
    AND creation_date <  '2023-01-01'
  GROUP BY month_start
)

SELECT
  FORMAT_DATE('%Y-%m', month_start)                        AS month,
  SAFE_DIVIDE(python_questions, total_questions)          AS python_question_proportion
FROM monthly_counts
ORDER BY month;