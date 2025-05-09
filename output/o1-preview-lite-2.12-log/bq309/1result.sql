WITH badge_counts AS (
  SELECT user_id, COUNT(*) AS badge_count
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)
SELECT
  q.id AS Question_ID,
  LENGTH(q.body) AS Body_Length,
  COALESCE(u.reputation, 0) AS User_Reputation,
  COALESCE(q.score, 0) AS Question_Score,
  COALESCE(bc.badge_count, 0) AS Badge_Count
FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
LEFT JOIN `bigquery-public-data.stackoverflow.users` AS u
  ON q.owner_user_id = u.id
LEFT JOIN badge_counts AS bc
  ON u.id = bc.user_id
WHERE
  q.accepted_answer_id IS NOT NULL
  OR EXISTS (
    SELECT 1
    FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
    WHERE
      a.parent_id = q.id
      AND q.view_count > 0
      AND ROUND(COALESCE(a.score, 0) / NULLIF(q.view_count, 0), 4) > 0.01
  )
ORDER BY Body_Length DESC, Question_ID DESC
LIMIT 10;