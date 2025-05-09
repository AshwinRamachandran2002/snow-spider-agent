SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  -- keep only questions whose title starts with "how"
  LOWER(title) LIKE 'how%'
  -- keep only Android–related questions (matches any of the listed tags)
  AND REGEXP_CONTAINS(
        COALESCE(tags, ''),
        r'(^|[\|])(android|android\-layout|android\-activity|android\-intent|android\-fragment|android\-studio|android\-listview|android\-recyclerview|android\-view|android\-service|android\-widget|android\-animation)([\|]|$)'
      )
ORDER BY
  view_count DESC,               -- most viewed first
  id                             -- deterministic tie‑breaker
LIMIT 1;