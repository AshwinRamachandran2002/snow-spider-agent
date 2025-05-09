WITH answer_counts AS (
  SELECT
    owner_user_id AS user_id,
    COUNT(*) AS total_answers
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
  answer_counts AS a
JOIN
  `bigquery-public-data.stackoverflow.users` AS u
ON
  u.id = a.user_id
WHERE
  u.reputation > 10
ORDER BY
  a.total_answers DESC
LIMIT 1;