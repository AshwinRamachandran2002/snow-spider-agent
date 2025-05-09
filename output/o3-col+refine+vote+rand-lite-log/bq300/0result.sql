SELECT
  MAX(answer_count) AS max_answers_python2_only
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  REGEXP_CONTAINS(LOWER(tags), r'python-2(\.|x|\d)?')      -- Python 2–specific
  AND NOT REGEXP_CONTAINS(LOWER(tags), r'python-3(\.|x|\d)?');  -- exclude any Python 3 involvement