WITH eligible_questions AS (
  SELECT
    q.id,
    q.body,
    q.owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE q.accepted_answer_id IS NOT NULL
     OR EXISTS (
       SELECT 1
       FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
       WHERE a.parent_id = q.id
         AND q.view_count IS NOT NULL
         AND q.view_count > 0
         AND SAFE_DIVIDE(a.score, q.view_count) > 0.01
     )
),
longest_questions AS (
  SELECT
    id            AS question_id,
    owner_user_id,
    LENGTH(body)  AS body_len
  FROM eligible_questions
  ORDER BY body_len DESC, id ASC
  LIMIT 10
),
badge_totals AS (
  SELECT
    user_id,
    COUNT(*) AS badge_total
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)
SELECT
  lq.question_id,
  u.reputation                         AS asker_reputation,
  (u.up_votes - u.down_votes)          AS asker_net_votes,
  COALESCE(bt.badge_total, 0)          AS asker_badge_total
FROM longest_questions AS lq
LEFT JOIN `bigquery-public-data.stackoverflow.users`   AS u  ON u.id = lq.owner_user_id
LEFT JOIN badge_totals                                 AS bt ON bt.user_id = lq.owner_user_id
ORDER BY lq.body_len DESC, lq.question_id;