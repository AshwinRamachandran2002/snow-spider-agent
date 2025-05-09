-- Monthly statistics for Stack Overflow users created in 2021
WITH new_users AS (   -- all users that signed‑up in 2021
  SELECT
    id                                   AS user_id,
    creation_date                        AS signup_ts,
    DATE_TRUNC(DATE(creation_date),MONTH) AS signup_month   -- first day of month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date)=2021
),

-- users that asked (at least) one question within 30 days of signing‑up
askers AS (
  SELECT
    u.user_id,
    MIN(q.creation_date) AS first_question_ts              -- first question date
  FROM new_users u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.owner_user_id = u.user_id
   AND q.creation_date BETWEEN u.signup_ts
                           AND TIMESTAMP_ADD(u.signup_ts,INTERVAL 30 DAY)
  GROUP BY u.user_id
),

-- among those askers, users that answered after their first question
-- and within 30 days of that first question
answerers AS (
  SELECT DISTINCT a.owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN askers aq
    ON aq.user_id = a.owner_user_id
   AND a.creation_date  >  aq.first_question_ts
   AND a.creation_date <= TIMESTAMP_ADD(aq.first_question_ts,INTERVAL 30 DAY)
),

-- per‑user flags
user_stats AS (
  SELECT
    u.signup_month,
    TRUE                                                AS user_present,
    IF(aq.user_id  IS NOT NULL, TRUE, FALSE)            AS asked_within_30,
    IF(ans.user_id IS NOT NULL, TRUE, FALSE)            AS answered_after_question
  FROM new_users u
  LEFT JOIN askers    aq  ON aq.user_id  = u.user_id
  LEFT JOIN answerers ans ON ans.user_id = u.user_id
)

-- final monthly aggregation
SELECT
  signup_month,
  COUNT(*)                                   AS total_new_users,
  COUNTIF(asked_within_30)                   AS users_asked_within_30_days,
  ROUND(100 * COUNTIF(asked_within_30) / COUNT(*),4)      AS pct_asked_within_30_days,
  COUNTIF(answered_after_question)           AS users_answered_after_question,
  ROUND(
        100 * COUNTIF(answered_after_question)
        / NULLIF(COUNTIF(asked_within_30),0)
       ,4)                                   AS pct_answered_after_question
FROM user_stats
GROUP BY signup_month
ORDER BY signup_month;