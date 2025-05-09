SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  -- Android‑related question (core tags or any tag that begins with “android‑”)
  REGEXP_CONTAINS(
    tags,
    r'(^|[|])(android-layout|android-activity|android-intent|android-fragments|android-service|android-view|android-[^|]+)([|]|$)'
  )
  -- Title starts with “how” (case‑insensitive)
  AND LOWER(title) LIKE 'how%'
ORDER BY
  view_count DESC          -- most viewed first
LIMIT 1;