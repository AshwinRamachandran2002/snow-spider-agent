SELECT
  u.display_name
FROM (
  SELECT
    owner_user_id,
    COUNT(*) AS answer_cnt
  FROM
    `bigquery-public-data.stackoverflow.stackoverflow_posts`
  WHERE
    post_type_id = 2                -- answers
    AND owner_user_id IS NOT NULL   -- only registered users
  GROUP BY
    owner_user_id
) AS a
JOIN `bigquery-public-data.stackoverflow.users` AS u
  ON a.owner_user_id = u.id
WHERE
  u.reputation > 10                 -- users with reputation greater than 10
ORDER BY
  a.answer_cnt DESC,                -- most answers
  u.reputation DESC                 -- tie‑breaker
LIMIT 1;