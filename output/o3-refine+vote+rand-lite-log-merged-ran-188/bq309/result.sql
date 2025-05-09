-- Top 10 longest questions that either  
--   * have an accepted answer, or  
--   * have no accepted answer but contain at least one answer whose
--     (answer‑score / question‑views) ratio > 0.01
-- For every selected question, return asker’s reputation, net votes
-- (up‑votes minus down‑votes) and total badge count.

WITH badge_counts AS (
  SELECT
    user_id,
    COUNT(*) AS badge_count
  FROM `bigquery-public-data.stackoverflow.badges`
  GROUP BY user_id
),

qualified_questions AS (          -- questions that meet the stated criteria
  SELECT
    q.id,
    q.owner_user_id,
    q.body,
    LENGTH(q.body) AS body_length
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE
        q.accepted_answer_id IS NOT NULL                       -- has accepted answer
     OR (                                                       -- OR no accepted answer but…
          q.accepted_answer_id IS NULL
          AND EXISTS (
                SELECT 1
                FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
                WHERE a.parent_id = q.id
                  AND q.view_count IS NOT NULL
                  AND q.view_count > 0
                  AND SAFE_DIVIDE(a.score, q.view_count) > 0.01  -- answer with high score/view ratio
          )
        )
)

SELECT
  q.id                       AS question_id,
  q.body_length,
  u.reputation,
  (u.up_votes - u.down_votes) AS net_votes,
  COALESCE(b.badge_count, 0)  AS badge_count
FROM qualified_questions AS q
LEFT JOIN `bigquery-public-data.stackoverflow.users`  AS u
       ON q.owner_user_id = u.id
LEFT JOIN badge_counts                            AS b
       ON q.owner_user_id = b.user_id
ORDER BY
  q.body_length DESC,
  q.id
LIMIT 10;