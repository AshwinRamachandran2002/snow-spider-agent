SELECT
  MAX(answer_count) AS max_answer_count
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  tags IS NOT NULL
  AND LOWER(tags) LIKE '%python-2%'   -- Python 2–specific tag(s)
  AND NOT LOWER(tags) LIKE '%python-3%'   -- exclude any Python 3 discussions