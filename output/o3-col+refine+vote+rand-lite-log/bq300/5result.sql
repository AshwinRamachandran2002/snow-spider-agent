SELECT
  MAX(answer_count) AS highest_answer_count_python2_only
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  tags LIKE '%python-2%'     -- question is explicitly about Python 2
  AND tags NOT LIKE '%python-3%' ;  -- exclude any that also involve Python 3