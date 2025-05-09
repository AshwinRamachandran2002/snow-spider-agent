WITH answer_counts AS (
  SELECT
    u.id,
    u.display_name,
    COUNT(*) AS answers_posted
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  JOIN `bigquery-public-data.stackoverflow.users`           AS u
    ON a.owner_user_id = u.id
  WHERE u.reputation > 10
  GROUP BY u.id, u.display_name
)
SELECT display_name
FROM answer_counts
ORDER BY answers_posted DESC
LIMIT 1;