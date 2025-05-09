SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  LOWER(title) LIKE 'how%'                                                -- “how” question
  AND EXISTS (                                                            -- has at least one wanted tag
    SELECT 1
    FROM UNNEST(SPLIT(tags, '|')) AS tag
    WHERE tag IN ('android', 'android-layout', 'android-activity', 'android-intent')
  )
ORDER BY
  view_count DESC                                                         -- most viewed first
LIMIT 1;