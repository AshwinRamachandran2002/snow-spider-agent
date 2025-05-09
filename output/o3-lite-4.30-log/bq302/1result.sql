SELECT
  FORMAT_DATE('%Y-%m', DATE_TRUNC(DATE(creation_date), MONTH)) AS month,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        tags IS NOT NULL AND (
          tags = 'python' OR                 -- only tag
          tags LIKE 'python|%' OR            -- first tag
          tags LIKE '%|python|%' OR          -- middle tag
          tags LIKE '%|python'               -- last tag
        )
      ),
      COUNT(*)                               -- total questions per month
    ),
    4
  ) AS python_question_proportion
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE EXTRACT(YEAR FROM creation_date) = 2022
GROUP BY month
ORDER BY month;