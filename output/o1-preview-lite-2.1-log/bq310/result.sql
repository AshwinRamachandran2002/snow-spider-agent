SELECT title
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE LOWER(title) LIKE '%how%'
  AND EXISTS (
    SELECT 1 FROM UNNEST(SPLIT(REGEXP_REPLACE(tags, '^<|>$', ''), '><')) AS tag
    WHERE LOWER(tag) LIKE '%android%'
  )
ORDER BY view_count DESC
LIMIT 1;