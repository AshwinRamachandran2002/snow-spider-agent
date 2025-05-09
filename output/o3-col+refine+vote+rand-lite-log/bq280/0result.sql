SELECT
  u.display_name
FROM (
  SELECT
    owner_user_id AS user_id,
    COUNT(*)      AS answer_cnt
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
) AS a
JOIN `bigquery-public-data.stackoverflow.users` AS u
  ON a.user_id = u.id
WHERE u.reputation > 10
ORDER BY a.answer_cnt DESC
LIMIT 1;