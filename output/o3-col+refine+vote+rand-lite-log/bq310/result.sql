SELECT title
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE LOWER(title) LIKE '%how%'
  AND EXISTS (
    SELECT 1
    FROM UNNEST(SPLIT(tags, '|')) AS tag
    WHERE tag IN (
      'android-layout','android-activity','android-intent',
      'android-fragment','android-studio','android-recyclerview',
      'android-listview','android-service','android-manifest',
      'android-broadcastreceiver'
    )
  )
ORDER BY view_count DESC
LIMIT 1;