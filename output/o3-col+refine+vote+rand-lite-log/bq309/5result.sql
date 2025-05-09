WITH ratio_ok AS (         -- questions that have an answer with score / views > 0.01
  SELECT DISTINCT a.parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`   AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = a.parent_id
  WHERE SAFE_DIVIDE(a.score, q.view_count) > 0.01
),
qualified_questions AS (   -- rule (A): accepted answer  OR  rule (B): ratio condition
  SELECT *
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE accepted_answer_id IS NOT NULL
  
  UNION DISTINCT
  
  SELECT q.*
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  WHERE q.accepted_answer_id IS NULL
    AND q.id IN (SELECT question_id FROM ratio_ok)
),
badges_per_user AS (       -- total badges per user
  SELECT user_id, COUNT(*) AS badge_total
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)

SELECT
  q.id                           AS question_id,
  BYTE_LENGTH(q.body)            AS body_length,
  u.reputation,
  (u.up_votes - u.down_votes)    AS net_votes,
  COALESCE(b.badge_total, 0)     AS total_badges
FROM   qualified_questions q
LEFT JOIN `bigquery-public-data.stackoverflow.users`  u
       ON u.id = q.owner_user_id
LEFT JOIN badges_per_user b
       ON b.user_id = q.owner_user_id
ORDER BY body_length DESC
LIMIT 10;