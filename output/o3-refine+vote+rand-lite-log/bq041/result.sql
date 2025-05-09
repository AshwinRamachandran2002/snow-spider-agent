-- Monthly statistics for new Stack Overflow users created in 2021
WITH users_2021 AS (       -- all users that signed‑up in 2021
  SELECT
    id                         AS user_id,
    creation_date              AS signup_ts,
    DATE_TRUNC(DATE(creation_date), MONTH) AS signup_month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),

questions AS (              -- all questions
  SELECT
    owner_user_id AS user_id,
    creation_date AS q_ts
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),

answers AS (                -- all answers
  SELECT
    owner_user_id AS user_id,
    creation_date AS a_ts
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),

first_question AS (         -- first question asked within 30 days of sign‑up
  SELECT
    u.user_id,
    MIN(q.q_ts) AS first_q_ts
  FROM users_2021 u
  JOIN questions q
    ON q.user_id = u.user_id
   AND q.q_ts >= u.signup_ts
   AND q.q_ts <  TIMESTAMP_ADD(u.signup_ts, INTERVAL 30 DAY)
  GROUP BY u.user_id
),

answer_after_question AS (  -- first answer posted after that question and within the next 30 days
  SELECT
    fq.user_id,
    MIN(a.a_ts) AS first_a_ts
  FROM first_question fq
  JOIN answers a
    ON a.user_id = fq.user_id
   AND a.a_ts  > fq.first_q_ts
   AND a.a_ts  < TIMESTAMP_ADD(fq.first_q_ts, INTERVAL 30 DAY)
  GROUP BY fq.user_id
),

user_flags AS (             -- flags per user for later aggregation
  SELECT
    u.signup_month,
    1                                    AS new_user,
    IF(fq.first_q_ts IS NOT NULL, 1, 0)  AS asked_in_30d,
    IF(fq.first_q_ts IS NOT NULL
       AND aa.first_a_ts IS NOT NULL, 1, 0) AS answered_after_q_in_30d
  FROM users_2021 u
  LEFT JOIN first_question        fq ON fq.user_id = u.user_id
  LEFT JOIN answer_after_question aa ON aa.user_id = u.user_id
)

SELECT
  signup_month,
  COUNT(*)                                               AS total_new_users,
  ROUND(100 * SUM(asked_in_30d)         / COUNT(*), 4)   AS pct_asked_question_within_30d,
  ROUND(100 * SUM(answered_after_q_in_30d)
              / NULLIF(SUM(asked_in_30d), 0), 4)         AS pct_of_those_askers_who_answered_within_30d
FROM user_flags
GROUP BY signup_month
ORDER BY signup_month;