SELECT
  MAX(answer_count) AS highest_python2_answer_count
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  tags LIKE '%python-2.%'                           -- question is Python-2 specific
  AND NOT (tags LIKE '%python-3%' OR tags LIKE '%python3%')  -- exclude any Python-3 related questions