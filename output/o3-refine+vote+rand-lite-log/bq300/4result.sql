SELECT
  MAX(answer_count) AS max_python2_answers
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  tags IS NOT NULL
  -- questions specifically about Python 2
  AND LOWER(tags) LIKE '%python-2%'
  -- exclude anything that also mentions Python 3
  AND LOWER(tags) NOT LIKE '%python-3%'