-- Top 10 longest questions that either
-- (a) have an accepted answer, or
-- (b) have no accepted answer but at least one answer whose
--     score-to-view ratio exceeds 0.01.
-- For each question return asker’s reputation, net votes and badge count.

WITH answers AS (
  -- all answers with their parent question id
  SELECT
    parent_id AS question_id,
    score
  FROM `bigquery-public-data.stackoverflow.stackoverflow_posts`
  WHERE post_type_id = 2                       -- answers
),
questions AS (
  SELECT
    id,
    owner_user_id,
    body,
    view_count,
    accepted_answer_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),
-- questions without accepted answer but with a high-ratio answer
ratio_ok AS (
  SELECT DISTINCT q.id
  FROM questions q
  JOIN answers  a ON a.question_id = q.id
  WHERE q.accepted_answer_id IS NULL
    AND a.score / NULLIF(q.view_count,0) > 0.01
),
-- union of the two eligibility paths
eligible_questions AS (
  SELECT id, owner_user_id, body
  FROM questions
  WHERE accepted_answer_id IS NOT NULL
  UNION ALL
  SELECT q.id, q.owner_user_id, q.body
  FROM questions q
  JOIN ratio_ok r ON r.id = q.id
),
-- user reputation and net votes
user_stats AS (
  SELECT
    id AS user_id,
    reputation,
    up_votes - down_votes AS net_votes
  FROM `bigquery-public-data.stackoverflow.users`
),
-- badge totals per user
badge_totals AS (
  SELECT
    user_id,
    COUNT(*) AS badge_count
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)

SELECT
  eq.id                           AS question_id,
  LENGTH(eq.body)                 AS body_length,
  us.reputation,
  us.net_votes,
  COALESCE(bt.badge_count, 0)     AS badge_count
FROM eligible_questions eq
LEFT JOIN user_stats  us ON us.user_id = eq.owner_user_id
LEFT JOIN badge_totals bt ON bt.user_id = eq.owner_user_id
ORDER BY body_length DESC
LIMIT 10;