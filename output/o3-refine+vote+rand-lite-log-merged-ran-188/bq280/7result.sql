SELECT
  u.display_name
FROM `bigquery-public-data.stackoverflow.stackoverflow_posts` AS p
JOIN `bigquery-public-data.stackoverflow.users`            AS u
  ON p.owner_user_id = u.id
WHERE p.post_type_id = 2          -- answers only
  AND u.reputation  > 10          -- users with reputation > 10
GROUP BY u.id, u.display_name, u.reputation
ORDER BY COUNT(*) DESC, u.reputation DESC, u.id
LIMIT 1;