WITH questions AS (
  SELECT
    q.id                                    AS question_id,
    q.title,
    q.body,
    CHAR_LENGTH(q.body)                     AS body_length,      -- length in characters
    q.accepted_answer_id,
    q.view_count,
    q.owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
),

-- 1) questions that already have an accepted answer
accepted_questions AS (
  SELECT *
  FROM questions
  WHERE accepted_answer_id IS NOT NULL
),

-- 2) questions without an accepted answer but with
--    at least one answer whose (answer_score / question_view_count) > 0.01
ratio_questions AS (
  SELECT DISTINCT q.*
  FROM questions AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.parent_id = q.question_id
  WHERE q.accepted_answer_id IS NULL
    AND q.view_count > 0
    AND (a.score / CAST(q.view_count AS FLOAT64)) > 0.01
),

candidate_questions AS (
  SELECT * FROM accepted_questions
  UNION ALL
  SELECT * FROM ratio_questions
),

-- user‑level statistics
user_stats AS (
  SELECT
    u.id                                    AS user_id,
    u.reputation,
    u.up_votes  - u.down_votes              AS net_votes,
    IFNULL(b.badge_count, 0)                AS badge_count
  FROM `bigquery-public-data.stackoverflow.users`   AS u
  LEFT JOIN (
      SELECT user_id, COUNT(*) AS badge_count
      FROM `bigquery-public-data.stackoverflow.badges`
      GROUP BY user_id
  ) AS b
  ON b.user_id = u.id
)

SELECT
  q.question_id,
  q.title,
  q.body_length,
  us.reputation,
  us.net_votes,
  us.badge_count
FROM candidate_questions AS q
LEFT JOIN user_stats AS us
  ON us.user_id = q.owner_user_id
ORDER BY
  q.body_length DESC,
  q.question_id
LIMIT 10;