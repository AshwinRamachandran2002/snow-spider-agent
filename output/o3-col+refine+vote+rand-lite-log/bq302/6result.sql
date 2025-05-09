WITH monthly_counts AS (
  SELECT
    EXTRACT(MONTH FROM creation_date) AS month,
    COUNT(*) AS total_questions,
    COUNTIF(
      REGEXP_CONTAINS(
        LOWER(tags),                 -- case-insensitive match
        r'(^|\|)python(\||$)'        -- matches the exact tag “python”
      )
    ) AS python_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
  GROUP BY month
)
SELECT
  month,
  total_questions,
  python_questions,
  ROUND(python_questions / total_questions, 4) AS python_share
FROM monthly_counts
ORDER BY month;