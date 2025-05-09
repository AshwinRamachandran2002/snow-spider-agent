-- Top 10 longest Stack Overflow questions that
--   • have an accepted answer OR
--   • (no accepted answer AND have at least one answer whose score / view_count > 0.01)
-- plus asker’s reputation, net votes and badge count
WITH question_stats AS (
  SELECT
    q.id                         AS question_id,
    q.owner_user_id,
    q.body,
    LENGTH(q.body)               AS body_length,
    q.accepted_answer_id,
    q.view_count
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
),
qualified_questions AS (
  -- questions with an accepted answer
  SELECT * FROM question_stats
  WHERE accepted_answer_id IS NOT NULL
  
  UNION DISTINCT
  
  -- questions without an accepted answer but with
  -- at least one “good” answer (score / view_count > 0.01)
  SELECT qs.*
  FROM question_stats qs
  WHERE qs.accepted_answer_id IS NULL
        AND qs.view_count IS NOT NULL
        AND qs.view_count > 0
        AND EXISTS (
              SELECT 1
              FROM `bigquery-public-data.stackoverflow.posts_answers` a
              WHERE a.parent_id = qs.question_id
                AND (a.score / CAST(qs.view_count AS FLOAT64)) > 0.01
        )
),
top10 AS (
  SELECT *
  FROM qualified_questions
  ORDER BY body_length DESC
  LIMIT 10
),
user_info AS (
  SELECT
    u.id                        AS user_id,
    u.reputation,
    u.up_votes - u.down_votes   AS net_votes
  FROM `bigquery-public-data.stackoverflow.users` u
),
badge_totals AS (
  SELECT
    user_id,
    COUNT(*) AS badge_count
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)
SELECT
  t.question_id,
  t.body_length,
  ui.reputation,
  ui.net_votes,
  COALESCE(bt.badge_count, 0) AS badge_count
FROM top10 t
LEFT JOIN user_info   ui ON ui.user_id = t.owner_user_id
LEFT JOIN badge_totals bt ON bt.user_id = t.owner_user_id
ORDER BY t.body_length DESC, t.question_id;