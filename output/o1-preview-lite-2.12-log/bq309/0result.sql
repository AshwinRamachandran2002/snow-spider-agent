SELECT
  q.id AS Question_ID,
  LENGTH(q.body) AS Body_Length,
  u.reputation AS User_Reputation,
  q.score AS Question_Score,
  IFNULL(b.badge_count, 0) AS Badge_Count
FROM
  `bigquery-public-data.stackoverflow.posts_questions` AS q
LEFT JOIN
  `bigquery-public-data.stackoverflow.users` AS u
ON
  q.owner_user_id = u.id
LEFT JOIN (
  SELECT user_id, COUNT(*) AS badge_count
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
) AS b
ON
  q.owner_user_id = b.user_id
WHERE
  q.accepted_answer_id IS NOT NULL
  OR EXISTS (
    SELECT 1
    FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
    WHERE a.parent_id = q.id
      AND a.score / NULLIF(q.view_count, 0) > 0.01
  )
ORDER BY
  LENGTH(q.body) DESC
LIMIT 10;