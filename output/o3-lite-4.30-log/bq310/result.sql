SELECT
  title
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE title IS NOT NULL
  AND LOWER(title) LIKE 'how %'  -- title starts with "how "
  AND tags IS NOT NULL
  AND REGEXP_CONTAINS(
        tags,
        r'(^|\|)(android|android-layout|android-activity|android-intent|android-fragment)(\||$)'
      )                          -- at least one of the specified Android‑related tags
ORDER BY view_count DESC
LIMIT 1;