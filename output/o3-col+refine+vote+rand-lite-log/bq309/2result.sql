-- Top-10 longest questions that either have an accepted answer
-- or (if not accepted) at least one answer whose score-to-view ratio > 0.01.
-- For each question return asker’s reputation, net votes and badge count.

WITH badges_per_user AS (
  SELECT
    user_id,
    COUNT(*) AS total_badges
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
),

qualified_questions AS (
  SELECT q.id,
         q.body,
         q.view_count,
         q.owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE
        -- keep questions with accepted answers …
        q.accepted_answer_id IS NOT NULL
     OR -- … or without accepted answers but with a “good” answer
        (q.accepted_answer_id IS NULL AND EXISTS (
            SELECT 1
            FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
            WHERE a.parent_id = q.id
              AND SAFE_DIVIDE(a.score , CAST(q.view_count AS FLOAT64)) > 0.01
        ))
)

SELECT
  q.id                             AS question_id,
  LENGTH(q.body)                   AS body_length,
  q.view_count,
  u.reputation,
  u.up_votes - u.down_votes        AS net_votes,
  COALESCE(b.total_badges,0)       AS total_badges
FROM qualified_questions AS q
JOIN `bigquery-public-data.stackoverflow.users`   AS u
  ON u.id = q.owner_user_id
LEFT JOIN badges_per_user           AS b
  ON b.user_id = u.id
ORDER BY body_length DESC
LIMIT 10;