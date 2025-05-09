SELECT
  MAX(answer_count) AS highest_python2_only_answer_count
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  tags LIKE '%python-2%'          -- Python 2–specific
  AND tags NOT LIKE '%python-3%'  -- exclude any Python 3 reference
;