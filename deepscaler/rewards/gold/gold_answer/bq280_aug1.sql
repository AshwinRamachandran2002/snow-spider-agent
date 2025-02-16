-- Task: List the display names, reputations, and answer counts of users with reputation greater than 10, sorted by answer count in descending order. Limit to the first 100 users.
WITH UserAnswers AS (
  SELECT
    owner_user_id AS answer_owner_id,
    COUNT(id) AS answer_count
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),
DetailedUsers AS (
  SELECT
    id AS user_id,
    display_name AS user_display_name,
    reputation
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE display_name IS NOT NULL AND reputation > 10
)
SELECT
  u.user_display_name,
  u.reputation,
  a.answer_count
FROM DetailedUsers u
JOIN UserAnswers a ON u.user_id = a.answer_owner_id
ORDER BY a.answer_count DESC
LIMIT 100;