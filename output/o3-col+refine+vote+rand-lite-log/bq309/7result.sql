-- Top-10 longest qualifying questions together with asker statistics
WITH
/* 1️⃣  Questions that have no accepted answer
       but contain at least one answer whose
       score-to-view ratio > 0.01                               */
ratio_ok AS (
  SELECT DISTINCT q.id
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers`  AS a
    ON a.parent_id = q.id
  WHERE q.accepted_answer_id IS NULL                       -- no accepted answer
    AND q.view_count IS NOT NULL
    AND q.view_count > 0                                   -- avoid div-by-zero
    AND CAST(a.score AS FLOAT64) / q.view_count > 0.01     -- ratio condition
),

/* 2️⃣  Candidate questions = (a) those with an accepted answer
       OR (b) those identified in ratio_ok                  */
candidate_questions AS (
  SELECT *
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE accepted_answer_id IS NOT NULL

  UNION ALL

  SELECT q.*
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN ratio_ok r
    ON r.id = q.id
),

/* 3️⃣  Basic user stats                                         */
user_stats AS (
  SELECT
    id                             AS user_id,
    reputation,
    up_votes - down_votes          AS net_votes
  FROM `bigquery-public-data.stackoverflow.users`
),

/* 4️⃣  Badge counts per user                                    */
badge_counts AS (
  SELECT
    user_id,
    COUNT(*)                       AS total_badges
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
)

/* 5️⃣  Final selection: top-10 longest bodies                   */
SELECT
  q.id                              AS question_id,
  LENGTH(q.body)                    AS body_length,
  u.reputation,
  u.net_votes,
  COALESCE(b.total_badges, 0)       AS total_badges
FROM   candidate_questions q
LEFT JOIN user_stats   u ON u.user_id = q.owner_user_id
LEFT JOIN badge_counts b ON b.user_id = q.owner_user_id
ORDER BY body_length DESC
LIMIT 10;