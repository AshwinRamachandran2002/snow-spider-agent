SELECT title
FROM `bigquery-public-data.stackoverflow.posts_questions` AS pq,
UNNEST(SPLIT(REGEXP_REPLACE(pq.tags, r'^<|>$', ''), '><')) AS tag
WHERE LOWER(pq.title) LIKE '%how%'
  AND LOWER(tag) LIKE 'android%'
ORDER BY pq.view_count DESC
LIMIT 1;