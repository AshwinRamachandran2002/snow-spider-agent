-- Monthly statistics for users who signed‑up in 2021
WITH new_users AS (      -- all users created in 2021
  SELECT
    id                          AS user_id,
    creation_date               AS signup_date,
    EXTRACT(MONTH FROM creation_date) AS signup_month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),

-- first question (if any) posted within 30 days of sign‑up
questions_within_30 AS (
  SELECT
    u.user_id,
    MIN(q.creation_date) AS first_question_date          -- first question time
  FROM new_users u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.owner_user_id = u.user_id
   AND q.creation_date BETWEEN u.signup_date
                           AND TIMESTAMP_ADD(u.signup_date, INTERVAL 30 DAY)
  GROUP BY u.user_id
),

-- users who answered at least one question after (and within 30 days of) their first question
answers_after_question AS (
  SELECT DISTINCT
    q.user_id
  FROM questions_within_30 q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON a.owner_user_id = q.user_id
   AND a.creation_date  >  q.first_question_date
   AND a.creation_date <= TIMESTAMP_ADD(q.first_question_date, INTERVAL 30 DAY)
)

SELECT
  u.signup_month                                   AS month,
  COUNT(*)                                         AS total_new_users,
  ROUND(100 * SAFE_DIVIDE(COUNT(q.user_id), COUNT(*)), 4)
      AS pct_with_question_within_30,
  ROUND(
        100 * SAFE_DIVIDE(COUNT(a.user_id), COUNT(q.user_id))
       , 4)                                        AS pct_of_those_who_then_answered
FROM new_users u
LEFT JOIN questions_within_30   q ON u.user_id = q.user_id
LEFT JOIN answers_after_question a ON u.user_id = a.user_id
GROUP BY month
ORDER BY month;