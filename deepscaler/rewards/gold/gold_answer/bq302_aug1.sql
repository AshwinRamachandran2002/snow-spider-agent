-- Task: What is the proportion of Stack Overflow questions tagged with 'python' in the year 2022?
SELECT
  ROUND(
    SAFE_DIVIDE(
      COUNTIF('python' IN UNNEST(SPLIT(LOWER(tags), '|'))),
      COUNT(*)
    ), 4
  ) AS Proportion
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  EXTRACT(YEAR FROM creation_date) = 2022