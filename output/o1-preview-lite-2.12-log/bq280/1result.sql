SELECT u.display_name
FROM `bigquery-public-data.stackoverflow.posts_answers` AS p
JOIN `bigquery-public-data.stackoverflow.users` AS u
  ON p.owner_user_id = u.id
WHERE u.reputation > 10
GROUP BY u.id, u.display_name
ORDER BY COUNT(*) DESC
LIMIT 1;