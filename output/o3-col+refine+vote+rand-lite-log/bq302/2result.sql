WITH monthly_totals AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(creation_date)) AS month_yyyy_mm,
    COUNT(*) AS total_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
  GROUP BY month_yyyy_mm
),
monthly_python AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(creation_date)) AS month_yyyy_mm,
    COUNT(*) AS python_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
    AND LOWER(tags) LIKE '%python%'
  GROUP BY month_yyyy_mm
)
SELECT
  t.month_yyyy_mm,
  COALESCE(p.python_questions, 0) AS python_questions,
  t.total_questions,
  ROUND(COALESCE(p.python_questions, 0) / t.total_questions, 4) AS python_proportion
FROM monthly_totals t
LEFT JOIN monthly_python p USING (month_yyyy_mm)
ORDER BY month_yyyy_mm;