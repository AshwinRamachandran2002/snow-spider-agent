-- Monthly proportion of 2022 Stack Overflow questions that are tagged with “python”
WITH questions_2022 AS (
  SELECT
    EXTRACT(MONTH FROM creation_date) AS month,
    tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2022
)

SELECT
  month,
  COUNTIF('python' IN UNNEST(SPLIT(IFNULL(tags, ''), '|'))) AS python_questions,
  COUNT(*) AS total_questions,
  SAFE_DIVIDE(
      COUNTIF('python' IN UNNEST(SPLIT(IFNULL(tags, ''), '|'))),
      COUNT(*)
  ) AS proportion_python
FROM questions_2022
GROUP BY month
ORDER BY month;