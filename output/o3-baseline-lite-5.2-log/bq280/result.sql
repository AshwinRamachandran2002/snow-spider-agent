WITH answer_counts AS (
  SELECT
    owner_user_id AS user_id,
    COUNT(*)      AS answer_total
  FROM
    `bigquery-public-data.stackoverflow.posts_answers`
  WHERE
    owner_user_id IS NOT NULL
  GROUP BY
    owner_user_id
)
SELECT
  u.display_name
FROM
  answer_counts AS ac
JOIN
  `bigquery-public-data.stackoverflow.users` AS u
ON
  ac.user_id = u.id
WHERE
  u.reputation > 10
ORDER BY
  ac.answer_total DESC,
  u.id            -- tie‑breaker
LIMIT 1;