SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  LOWER(title) LIKE 'how%'                                                  -- “how…” questions
  AND REGEXP_CONTAINS(IFNULL(tags, ''), r'(^|\|)android[-a-z0-9]*(\||$)')   -- any tag that starts with “android”
ORDER BY
  view_count DESC
LIMIT 1;