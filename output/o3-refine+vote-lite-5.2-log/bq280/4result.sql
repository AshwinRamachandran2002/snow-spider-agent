SELECT
  u.display_name
FROM (
  SELECT
    owner_user_id,
    COUNT(*) AS answer_count
  FROM
    `bigquery-public-data.stackoverflow.posts_answers`
  WHERE
    owner_user_id IS NOT NULL
  GROUP BY
    owner_user_id
) AS a
JOIN
  `bigquery-public-data.stackoverflow.users` AS u
ON
  a.owner_user_id = u.id
WHERE
  u.reputation > 10
ORDER BY
  a.answer_count DESC
LIMIT
  1;