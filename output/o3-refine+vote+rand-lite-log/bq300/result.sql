SELECT
  MAX(answer_count) AS highest_answer_count
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  answer_count IS NOT NULL
  -- must be explicitly tagged for Python 2 (e.g. python-2, python-2.7, python-2.x …)
  AND REGEXP_CONTAINS(tags, r'(^|\|)python-2(\.|$|\|)')
  -- exclude anything also tagged for Python 3 (e.g. python-3, python-3.x …)
  AND NOT REGEXP_CONTAINS(tags, r'(^|\|)python-3(\.|$|\|)');