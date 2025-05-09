SELECT
  `title`
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  LOWER(`title`) LIKE 'how %'                              -- “How …” questions
  AND REGEXP_CONTAINS(`tags`,
        r'android-(layout|activity|intent|fragment|studio)') -- Android-related tags
ORDER BY
  `view_count` DESC
LIMIT 1;