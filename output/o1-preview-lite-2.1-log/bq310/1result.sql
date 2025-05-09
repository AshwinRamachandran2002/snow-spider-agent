SELECT title
FROM `bigquery-public-data.stackoverflow.stackoverflow_posts`
WHERE post_type_id = 1
  AND LOWER(title) LIKE '%how%'
  AND LOWER(tags) LIKE '%android%'
ORDER BY view_count DESC
LIMIT 1;