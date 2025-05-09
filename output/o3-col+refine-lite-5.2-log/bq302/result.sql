WITH total AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(creation_date)) AS month,
    COUNT(*) AS total_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
  GROUP BY month
),
python AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(creation_date)) AS month,
    COUNT(*) AS python_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
    AND tags LIKE '%python%'
  GROUP BY month
)
SELECT
  t.month,
  p.python_questions,
  t.total_questions,
  SAFE_DIVIDE(p.python_questions, t.total_questions) AS python_question_proportion
FROM total AS t
LEFT JOIN python AS p
USING (month)
ORDER BY t.month;