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
JOIN
  `bigquery-public-data.stackoverflow.users` AS u
ON
  a.owner_user_id = u.id
WHERE
  u.reputation > 10
ORDER BY
  a.answers_posted DESC,
  u.id ASC          -- tie‑breaker (optional)
LIMIT 1;