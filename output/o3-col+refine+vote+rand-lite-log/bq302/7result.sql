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
    AND REGEXP_CONTAINS(tags, r'(^|[|])python([|]|$)')
  GROUP BY month
)
SELECT
  t.month,
  ROUND(SAFE_DIVIDE(COALESCE(p.python_questions, 0), t.total_questions), 4) AS proportion_python
FROM total t
LEFT JOIN python p USING (month)
ORDER BY t.month;