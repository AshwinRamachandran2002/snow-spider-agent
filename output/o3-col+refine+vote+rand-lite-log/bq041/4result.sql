WITH new_users AS (
  -- every Stack Overflow account created in 2021
  SELECT
    id                             AS user_id,
    creation_date                  AS signup_ts,
    DATE_TRUNC(DATE(creation_date), MONTH) AS signup_month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),

asked AS (
  -- first question asked by those users within 30 days of sign-up
  SELECT
    u.user_id,
    MIN(q.creation_date) AS first_question_ts
  FROM new_users AS u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.owner_user_id = u.user_id
   AND q.creation_date BETWEEN u.signup_ts
                           AND TIMESTAMP_ADD(u.signup_ts, INTERVAL 30 DAY)
  GROUP BY u.user_id
),

answered AS (
  -- did they answer ≥ 1 question after their first question,
  -- still inside the 30-day window that starts at that first question?
  SELECT DISTINCT
    a.user_id
  FROM asked AS a
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS ans
    ON ans.owner_user_id = a.user_id
   AND ans.creation_date >  a.first_question_ts
   AND ans.creation_date <= TIMESTAMP_ADD(a.first_question_ts, INTERVAL 30 DAY)
)

SELECT
  nu.signup_month,
  COUNT(*)                                               AS new_users,
  ROUND(100 * COUNTIF(ask.user_id IS NOT NULL) / COUNT(*), 4)
      AS pct_with_question_30d,
  ROUND(
        100 * COUNTIF(ans.user_id IS NOT NULL)
        / NULLIF(COUNTIF(ask.user_id IS NOT NULL), 0)
       , 4)                                              AS pct_askers_with_answer_30d
FROM new_users AS nu
LEFT JOIN asked    AS ask ON ask.user_id = nu.user_id
LEFT JOIN answered AS ans ON ans.user_id = nu.user_id
GROUP BY nu.signup_month
ORDER BY nu.signup_month;