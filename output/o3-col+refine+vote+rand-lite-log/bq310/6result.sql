SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  REGEXP_CONTAINS(tags,
    r'(android\-layout|android\-activity|android\-intent|android\-fragment|android\-studio)')
  AND REGEXP_CONTAINS(LOWER(title), r'\bhow\b')
ORDER BY
  view_count DESC
LIMIT 1;