SELECT
  MAX(answer_count) AS max_answers_python2_question
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  answer_count IS NOT NULL
  AND tags IS NOT NULL
  -- keep questions that are explicitly about Python 2
  AND REGEXP_CONTAINS(tags, r'(^|[|])python-?2(\.[0-9x]+)?([|]|$)')
  -- exclude any questions that mention Python 3
  AND NOT REGEXP_CONTAINS(tags, r'(^|[|])python-?3(\.[0-9x]+)?([|]|$)');