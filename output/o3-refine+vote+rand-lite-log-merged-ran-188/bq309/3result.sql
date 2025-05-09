-- Top‑10 longest questions that either have an accepted answer
-- or (no accepted answer AND at least one answer with score/view_ratio > 0.01).
-- For every question list asker’s reputation, net votes and badge count.

WITH answers_high AS (
  -- questions (without accepted answer) that have at least one “high‑ratio” answer
  SELECT DISTINCT a.parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`  AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
        ON q.id = a.parent_id
  WHERE q.accepted_answer_id IS NULL
        AND q.view_count IS NOT NULL
        AND q.view_count > 0
        AND CAST(a.score AS FLOAT64) / CAST(q.view_count AS FLOAT64) > 0.01
),

qualified_questions AS (
  -- questions that fulfil either of the two required conditions
  SELECT
        q.id,
        q.owner_user_id,
        LENGTH(q.body) AS body_length
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE q.accepted_answer_id IS NOT NULL
        OR q.id IN (SELECT question_id FROM answers_high)
),

user_badges AS (
  -- total number of badges per user
  SELECT
        user_id,
        COUNT(*) AS badge_count
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)

SELECT
      qq.id                           AS question_id,
      qq.body_length,
      u.reputation,
      (u.up_votes - u.down_votes)     AS net_votes,
      COALESCE(ub.badge_count, 0)     AS total_badges
FROM qualified_questions AS qq
LEFT JOIN `bigquery-public-data.stackoverflow.users`  AS u
       ON u.id = qq.owner_user_id
LEFT JOIN user_badges AS ub
       ON ub.user_id = qq.owner_user_id
ORDER BY
      qq.body_length DESC,
      qq.id
LIMIT 10;