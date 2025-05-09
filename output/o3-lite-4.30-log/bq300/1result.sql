SELECT
  MAX(answer_count) AS highest_answer_count
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  LOWER(tags) LIKE '%python-2%'
  AND LOWER(tags) NOT LIKE '%python-3%';