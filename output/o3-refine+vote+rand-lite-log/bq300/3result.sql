SELECT
  MAX(answer_count) AS max_answers_python2_question
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  REGEXP_CONTAINS(tags, r'(?i)python-2')           -- question is specific to Python 2
  AND NOT REGEXP_CONTAINS(tags, r'(?i)python-3')   -- exclude any Python 3 references