SELECT
  MAX(answer_count) AS highest_answer_count
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  tags IS NOT NULL
  -- questions specifically about Python 2 …
  AND REGEXP_CONTAINS(tags, r'(^|\|)python-?2(\.|x|\||$)')
  -- … while excluding anything that involves Python 3
  AND NOT REGEXP_CONTAINS(tags, r'(^|\|)python-?3(\.|x|\||$)');