-- Monthly 2021 user-engagement funnel on Stack Overflow
WITH new_users AS (
  SELECT
    id,
    creation_date
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE creation_date BETWEEN '2021-01-01' AND '2021-12-31'
),

questioners AS (         -- users who asked ≥1 question within 30 days of sign-up
  SELECT
    u.id,
    u.creation_date,
    MIN(q.creation_date) AS first_question_dt
  FROM new_users AS u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.owner_user_id = u.id
   AND q.creation_date  <= TIMESTAMP_ADD(u.creation_date, INTERVAL 30 DAY)
  GROUP BY u.id, u.creation_date
),

answerers AS (           -- those questioners who answered within 30 days *after* their first question
  SELECT DISTINCT q.id AS user_id
  FROM questioners AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.owner_user_id  = q.id
   AND a.creation_date  >  q.first_question_dt
   AND a.creation_date  <= TIMESTAMP_ADD(q.first_question_dt, INTERVAL 30 DAY)
)

SELECT
  FORMAT_DATE('%Y-%m', DATE(u.creation_date))                                AS month,
  COUNT(DISTINCT u.id)                                                       AS total_new_users,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT q.id), COUNT(DISTINCT u.id)), 4)    AS pct_with_question,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT a.user_id), COUNT(DISTINCT q.id)),4)AS pct_answered_after_question
FROM new_users u
LEFT JOIN questioners q ON q.id      = u.id
LEFT JOIN answerers   a ON a.user_id = u.id
GROUP BY month
ORDER BY month;