SELECT
  title
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE LOWER(title) LIKE '%how%'
  AND REGEXP_CONTAINS(
        tags,
        r'(^|\|)(android|android-layout|android-activity|android-intent|android-fragment|android-studio|android-manifest|android-service|android-recyclerview|android-gradle|android-webview)(\||$)'
      )
ORDER BY view_count DESC
LIMIT 1;