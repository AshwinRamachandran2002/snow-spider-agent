SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  title IS NOT NULL
  AND REGEXP_CONTAINS(LOWER(title), r'\bhow\b')                      -- “how” appears in the title
  AND REGEXP_CONTAINS(tags, r'(^|\|)android(-[^|]*)?(\||$)')         -- tag is android or starts with android-
ORDER BY
  view_count DESC,                                                   -- most‑viewed first
  id                                                                 -- tie‑breaker
LIMIT 1;