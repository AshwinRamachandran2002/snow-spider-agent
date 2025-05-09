SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`,
  UNNEST(SPLIT(tags, '|')) AS tag
WHERE
  REGEXP_CONTAINS(LOWER(title), r'\bhow\b')                     -- “how” in the title
  AND tag IN (                                                   -- Android‑related tags of interest
        'android-layout',
        'android-activity',
        'android-intent',
        'android-fragment',
        'android-studio',
        'android-recyclerview',
        'android-service',
        'android-view',
        'android-widget',
        'android-animation'
      )
ORDER BY
  view_count DESC,           -- most viewed first
  id            ASC          -- deterministic tie‑breaker
LIMIT 1;