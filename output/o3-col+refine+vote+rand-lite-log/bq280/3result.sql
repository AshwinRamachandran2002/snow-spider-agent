SELECT
  u.display_name
FROM (
  SELECT
    owner_user_id,
    COUNT(*) AS answers_posted
  FROM
    `bigquery-public-data.stackoverflow.posts_answers`
  WHERE
    owner_user_id IS NOT NULL
  GROUP BY
    owner_user_id
) AS a
JOIN `bigquery-public-data.stackoverflow.users` AS u
  ON u.id = a.owner_user_id
WHERE
  u.reputation > 10
ORDER BY
  a.answers_posted DESC
LIMIT 1;