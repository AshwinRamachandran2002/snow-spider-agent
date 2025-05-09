SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  LOWER(title) LIKE '%how%'                       -- “how” appears in the title
  AND REGEXP_CONTAINS(tags, r'(^|\|)(android-layout|android-activity|android-intent)(\||$)') -- at least one of the specified Android‑related tags
ORDER BY
  view_count DESC                                  -- most viewed first
LIMIT 1;                                           -- return the single top result