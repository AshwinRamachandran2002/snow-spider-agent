SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  REGEXP_CONTAINS(LOWER(title), r'\bhow\b')               
  AND (
        SELECT COUNTIF(LOWER(tag) IN (
          'android', 'android-layout', 'android-activity',
          'android-intent', 'android-fragment', 'android-studio',
          'android-recyclerview', 'android-listview'
        ))
        FROM UNNEST(SPLIT(tags, '|')) AS tag
      ) > 0
ORDER BY
  view_count DESC
LIMIT 1;