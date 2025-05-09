WITH badge_counts AS (
  SELECT
    user_id,
    COUNT(*) AS badge_total
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
),
qualifying_questions AS (
  SELECT
    q.id AS question_id,
    LENGTH(q.body) AS body_length,
    q.owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE
        q.accepted_answer_id IS NOT NULL
     OR (
          q.accepted_answer_id IS NULL
          AND EXISTS (
                SELECT 1
                FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
                WHERE a.parent_id = q.id
                  AND SAFE_DIVIDE(a.score, NULLIF(q.view_count,0)) > 0.01
          )
     )
)
SELECT
  qq.question_id,
  u.reputation              AS asker_reputation,
  (u.up_votes - u.down_votes) AS asker_net_votes,
  COALESCE(b.badge_total,0) AS asker_badge_total
FROM qualifying_questions AS qq
JOIN `bigquery-public-data.stackoverflow.users`  AS u
  ON u.id = qq.owner_user_id
LEFT JOIN badge_counts AS b
  ON b.user_id = qq.owner_user_id
ORDER BY qq.body_length DESC, qq.question_id
LIMIT 10;