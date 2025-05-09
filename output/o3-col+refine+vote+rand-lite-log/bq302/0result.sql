WITH questions_2022 AS (
  SELECT
    EXTRACT(MONTH FROM creation_date) AS month,
    tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
),
monthly_totals AS (
  SELECT
    month,
    COUNT(*) AS total_questions,
    COUNTIF(REGEXP_CONTAINS(tags, r'(^|\|)python($|\|)')) AS python_questions
  FROM questions_2022
  GROUP BY month
)
SELECT
  month,
  python_questions,
  total_questions,
  SAFE_DIVIDE(python_questions, total_questions) AS python_question_proportion
FROM monthly_totals
ORDER BY month;