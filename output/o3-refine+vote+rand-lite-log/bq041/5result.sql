/* Monthly statistics for new Stack Overflow users created in 2021 */
WITH new_users AS (
  SELECT
    id                                              AS user_id,
    DATE(creation_date)                             AS signup_date,
    FORMAT_DATE('%Y-%m', DATE(creation_date))       AS signup_month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE DATE(creation_date) BETWEEN '2021-01-01' AND '2021-12-31'
),

/* first question asked within 30 days of sign‑up */
questions_within_30d AS (
  SELECT
    u.user_id,
    u.signup_month,
    MIN(DATE(p.creation_date)) AS first_question_date          -- first question date
  FROM new_users AS u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS p
    ON  p.owner_user_id = u.user_id
    AND DATE(p.creation_date) >= u.signup_date
    AND DATE(p.creation_date) <  DATE_ADD(u.signup_date, INTERVAL 30 DAY)
  GROUP BY u.user_id, u.signup_month
),

/* users who answered at least one question after their first question
   and within 30 days of that first question */
answers_after_question AS (
  SELECT DISTINCT
    q.user_id
  FROM questions_within_30d AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON  a.owner_user_id = q.user_id
    AND DATE(a.creation_date) >  q.first_question_date
    AND DATE(a.creation_date) <  DATE_ADD(q.first_question_date, INTERVAL 30 DAY)
)

SELECT
  nu.signup_month                                          AS month,
  COUNT(*)                                                 AS total_new_users,
  ROUND(SAFE_DIVIDE(COUNT(q.user_id), COUNT(*)) * 100, 4)  AS pct_new_users_asked_question,
  ROUND(
        SAFE_DIVIDE(
          COUNT(DISTINCT CASE WHEN a.user_id IS NOT NULL THEN nu.user_id END),
          COUNT(q.user_id)
        ) * 100, 4)                                        AS pct_askers_who_answered
FROM new_users AS nu
LEFT JOIN questions_within_30d   AS q ON q.user_id = nu.user_id
LEFT JOIN answers_after_question AS a ON a.user_id = nu.user_id
GROUP BY month
ORDER BY month;