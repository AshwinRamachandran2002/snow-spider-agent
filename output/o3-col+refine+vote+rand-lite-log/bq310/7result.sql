SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  REGEXP_CONTAINS(tags, r'\bandroid-(layout|activity|intent|fragment|view|studio)\b')
  AND REGEXP_CONTAINS(LOWER(title), r'\bhow\b')
ORDER BY
  view_count DESC
LIMIT 1;