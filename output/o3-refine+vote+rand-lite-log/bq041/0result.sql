WITH users2021 AS (
  SELECT
    id                              AS user_id,
    DATE(creation_date)             AS signup_date,
    FORMAT_DATE('%Y-%m', DATE(creation_date)) AS signup_month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),

-- first question asked within 30 days of sign‑up
user_first_question AS (
  SELECT
    u.user_id,
    MIN(DATE(q.creation_date)) AS first_question_date
  FROM users2021 u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.owner_user_id = u.user_id
   AND DATE(q.creation_date) BETWEEN u.signup_date
                                 AND DATE_ADD(u.signup_date, INTERVAL 30 DAY)
  GROUP BY u.user_id
),

-- any answer posted after that first question and within 30 days of it
user_answer_after_question AS (
  SELECT DISTINCT
    uq.user_id
  FROM user_first_question uq
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON a.owner_user_id = uq.user_id
   AND DATE(a.creation_date) >  uq.first_question_date
   AND DATE(a.creation_date) <= DATE_ADD(uq.first_question_date, INTERVAL 30 DAY)
)

SELECT
  u.signup_month                                                          AS month,
  COUNT(*)                                                                AS total_new_users,
  COUNTIF(uq.first_question_date IS NOT NULL)                             AS users_asked_within_30,
  SAFE_DIVIDE(
    COUNTIF(uq.first_question_date IS NOT NULL), COUNT(*)
  ) * 100                                                                 AS pct_asked_within_30,
  COUNTIF(ua.user_id IS NOT NULL)                                         AS askers_who_answered_within_30,
  SAFE_DIVIDE(
    COUNTIF(ua.user_id IS NOT NULL),
    NULLIF(COUNTIF(uq.first_question_date IS NOT NULL),0)
  ) * 100                                                                 AS pct_answer_after_question
FROM users2021 u
LEFT JOIN user_first_question      uq ON u.user_id = uq.user_id
LEFT JOIN user_answer_after_question ua ON u.user_id = ua.user_id
GROUP BY month
ORDER BY month;