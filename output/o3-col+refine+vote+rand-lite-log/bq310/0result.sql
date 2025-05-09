SELECT
  title
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  LOWER(title) LIKE '%how%'                                                -- only questions containing "how" in the title
  AND REGEXP_CONTAINS(tags, r'(android-layout|android-activity|android-intent|android-fragment|android-studio)')
ORDER BY
  view_count DESC                                                          -- most-viewed first
LIMIT 1;                                                                   -- pick the single top question