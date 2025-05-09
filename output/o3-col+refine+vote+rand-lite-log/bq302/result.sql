-- Monthly proportion of 2022 Stack Overflow questions tagged with 'python'
WITH total_questions AS (
  SELECT
    EXTRACT(MONTH FROM creation_date) AS month,
    COUNT(*) AS total_cnt
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
  GROUP BY month
),
python_questions AS (
  SELECT
    EXTRACT(MONTH FROM creation_date) AS month,
    COUNT(*) AS python_cnt
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
    AND REGEXP_CONTAINS(tags, r'(^|[|])python([|]|$)')
  GROUP BY month
)
SELECT
  t.month,
  p.python_cnt,
  t.total_cnt,
  SAFE_DIVIDE(p.python_cnt, t.total_cnt) AS python_share
FROM total_questions t
LEFT JOIN python_questions p USING (month)
ORDER BY month;