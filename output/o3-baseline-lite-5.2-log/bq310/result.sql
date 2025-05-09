-- Most‑viewed Android‑related “How …” question on Stack Overflow
WITH relevant_tags AS (
  SELECT tag
  FROM UNNEST([
      'android', 'android-layout', 'android-activity', 'android-intent',
      'android-fragment', 'android-fragments', 'android-studio',
      'android-view', 'android-recyclerview', 'android-service',
      'android-broadcastreceiver', 'android-widget'
  ]) AS tag
)

SELECT
  q.title
FROM
  `bigquery-public-data.stackoverflow.posts_questions` AS q
WHERE
  LOWER(q.title) LIKE 'how %'                        -- “how” questions
  AND EXISTS (                                       -- at least one wanted tag
        SELECT 1
        FROM UNNEST(SPLIT(q.tags, '|')) AS tag
        JOIN relevant_tags USING (tag)
  )
ORDER BY
  q.view_count DESC                                  -- most viewed
LIMIT 1;