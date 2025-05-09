SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  LOWER(title) LIKE '%how%'                                         -- the word “how” appears in the title
  AND REGEXP_CONTAINS(                                              -- at least one of the Android-related tags
        tags,
        r'(^|[|])(android|android-layout|android-activity|android-intent|android-fragment|android-studio)([|]|$)'
      )
ORDER BY
  view_count DESC                                                   -- most-viewed first
LIMIT 1;                                                            -- top question only