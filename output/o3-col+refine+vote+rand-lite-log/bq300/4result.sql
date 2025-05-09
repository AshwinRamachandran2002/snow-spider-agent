SELECT
  MAX(answer_count) AS highest_python2_only_answer_count
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  -- keep questions that mention Python 2
  REGEXP_CONTAINS(tags, r'python-2')
  -- exclude any that also mention Python 3 (python-3.x, python-3, python3, etc.)
  AND NOT REGEXP_CONTAINS(tags, r'python-?3')