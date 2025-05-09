-- Return the 10 longest questions that either
--   a) have an accepted answer, or
--   b) have no accepted answer but at least one answer whose
--      score‑to‑view ratio exceeds 0.01.
-- For each question show the asker's reputation, net votes and badge count.

WITH candidate_questions AS (
  SELECT
    q.id,
    q.body,
    q.owner_user_id,
    q.view_count,
    LENGTH(q.body) AS body_len
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE
        q.accepted_answer_id IS NOT NULL
     OR (
          q.accepted_answer_id IS NULL
          AND q.view_count > 0
          AND EXISTS (
                SELECT 1
                FROM `bigquery-public-data.stackoverflow.posts_answers` a
                WHERE a.parent_id = q.id
                  AND a.score / CAST(q.view_count AS FLOAT64) > 0.01
          )
        )
),
top10 AS (
  SELECT *
  FROM candidate_questions
  ORDER BY body_len DESC
  LIMIT 10
),
user_stats AS (
  SELECT
    u.id                              AS user_id,
    u.reputation,
    (u.up_votes - u.down_votes)       AS net_votes,
    COALESCE(b.badge_cnt, 0)          AS badge_cnt
  FROM `bigquery-public-data.stackoverflow.users` u
  LEFT JOIN (
    SELECT user_id, COUNT(*) AS badge_cnt
    FROM `bigquery-public-data.stackoverflow.badges`
    GROUP BY user_id
  ) b
  ON u.id = b.user_id
)

SELECT
  q.id                AS question_id,
  q.body_len          AS body_length,
  us.reputation,
  us.net_votes,
  us.badge_cnt        AS total_badges
FROM top10 q
LEFT JOIN user_stats us
ON q.owner_user_id = us.user_id
ORDER BY
  body_length DESC,
  question_id;