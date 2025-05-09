WITH wanted_tags AS (
  SELECT 'android-layout'  AS tag UNION ALL
  SELECT 'android-activity' UNION ALL
  SELECT 'android-intent'  UNION ALL
  SELECT 'android-fragment' UNION ALL
  SELECT 'android-studio'  UNION ALL
  SELECT 'android-recyclerview'
)
SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions` AS q
WHERE
  LOWER(title) LIKE 'how %'                     -- “how” questions
  AND EXISTS (                                  -- contains at least one wanted Android-related tag
    SELECT 1
    FROM wanted_tags t
    WHERE q.tags LIKE CONCAT('%', t.tag, '%')
  )
ORDER BY
  view_count DESC                               -- most viewed first
LIMIT 1;