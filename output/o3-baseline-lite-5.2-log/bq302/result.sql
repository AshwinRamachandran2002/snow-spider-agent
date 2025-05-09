-- Monthly proportion of Stack Overflow questions tagged with 'python' in 2022
WITH questions_2022 AS (
  SELECT
    DATE_TRUNC(DATE(`creation_date`), MONTH) AS month_start,
    COUNT(*) AS total_questions,
    SUM(
      CASE
        WHEN 'python' IN UNNEST(SPLIT(`tags`, '|')) THEN 1
        ELSE 0
      END
    ) AS python_questions
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`
  WHERE
    EXTRACT(YEAR FROM `creation_date`) = 2022
  GROUP BY
    month_start
)
SELECT
  FORMAT_DATE('%Y-%m', month_start) AS month,
  python_questions / total_questions AS proportion_python
FROM
  questions_2022
ORDER BY
  month_start;