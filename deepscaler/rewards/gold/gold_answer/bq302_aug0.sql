-- Task: For each month in the year 2022, compute the proportion of Stack Overflow questions tagged with 'python' out of all questions created that month.
SELECT
  FORMAT_DATE('%b-%Y', DATE_TRUNC(creation_date, MONTH)) AS Month,
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
GROUP BY
  Month
ORDER BY
  PARSE_DATE('%b-%Y', Month)