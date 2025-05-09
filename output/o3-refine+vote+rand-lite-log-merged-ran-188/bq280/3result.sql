SELECT u.display_name
FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
JOIN `bigquery-public-data.stackoverflow.users` AS u
  ON u.id = a.owner_user_id
WHERE a.owner_user_id IS NOT NULL
  AND u.reputation > 10
GROUP BY u.id, u.display_name
ORDER BY COUNT(*) DESC, u.id
LIMIT 1;