/*  Monthly statistics for new Stack Overflow users created in 2021  */
WITH new_users AS (
  SELECT
    u.id                         AS user_id,
    DATE(u.creation_date)        AS user_creation_date,
    FORMAT_DATE('%Y-%m', DATE(u.creation_date)) AS user_month
  FROM `bigquery-public-data.stackoverflow.users` u
  WHERE DATE(u.creation_date) BETWEEN '2021-01-01' AND '2021-12-31'
),

/* first question (if any) asked within 30 days of sign‑up */
questions_within_30 AS (
  SELECT
    n.user_id,
    MIN(DATE(q.creation_date)) AS first_question_date
  FROM new_users n
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.owner_user_id = n.user_id
   AND DATE(q.creation_date) BETWEEN n.user_creation_date
                                 AND DATE_ADD(n.user_creation_date, INTERVAL 30 DAY)
  GROUP BY n.user_id
),

/* users who answered at least one question after that first question
   and within 30 days of the first question                       */
answers_within_30_of_question AS (
  SELECT DISTINCT
    q.user_id
  FROM questions_within_30 q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON a.owner_user_id = q.user_id
   AND DATE(a.creation_date)  > q.first_question_date
   AND DATE(a.creation_date) <= DATE_ADD(q.first_question_date, INTERVAL 30 DAY)
)

SELECT
  nu.user_month                                             AS month,
  COUNT(*)                                                  AS total_new_users,
  COUNT(q.user_id)                                          AS users_asked_question_30d,
  ROUND(100 * COUNT(q.user_id) / COUNT(*), 4)               AS pct_asked_question_30d,
  COUNT(a.user_id)                                          AS users_answered_after_question_30d,
  ROUND(
        100 * COUNT(a.user_id) / NULLIF(COUNT(q.user_id),0)
       , 4)                                                 AS pct_answered_after_question_30d
FROM new_users                           nu
LEFT JOIN questions_within_30            q ON q.user_id = nu.user_id
LEFT JOIN answers_within_30_of_question  a ON a.user_id = nu.user_id
GROUP BY nu.user_month
ORDER BY nu.user_month;