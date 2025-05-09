WITH new_users AS (
  -- all Stack Overflow users that signed‑up in 2021
  SELECT
    id                                  AS user_id,
    creation_date,
    DATE_TRUNC(DATE(creation_date), MONTH) AS month_start          -- 1st day of month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),
first_questions AS (
  -- each 2021 user’s first question asked within 30 days of sign‑up
  SELECT
    u.user_id,
    MIN(q.creation_date) AS first_question_date
  FROM new_users u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.owner_user_id = u.user_id
   AND q.creation_date BETWEEN u.creation_date
                           AND u.creation_date + INTERVAL 30 DAY
  GROUP BY u.user_id
),
answered_within_30d AS (
  -- users who, after that first question, answered ≥1 question
  -- within the next 30 days
  SELECT DISTINCT
    fq.user_id
  FROM first_questions fq
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON a.owner_user_id = fq.user_id
   AND a.creation_date  >  fq.first_question_date
   AND a.creation_date  <= fq.first_question_date + INTERVAL 30 DAY
),
per_user_flags AS (
  -- flags per user used for monthly aggregation
  SELECT
    u.month_start,
    u.user_id,
    IF(fq.first_question_date IS NOT NULL, 1, 0)           AS asked_in_30d,
    IF(fq.first_question_date IS NOT NULL
       AND aw.user_id IS NOT NULL, 1, 0)                   AS asked_then_answered
  FROM new_users u
  LEFT JOIN first_questions    fq ON fq.user_id = u.user_id
  LEFT JOIN answered_within_30d aw ON aw.user_id = u.user_id
)
SELECT
  FORMAT_DATE('%Y-%m', month_start)                                   AS month,
  COUNT(*)                                                            AS new_users,
  ROUND(SAFE_DIVIDE(SUM(asked_in_30d)       , COUNT(*)) * 100, 4)     AS pct_asked_within_30d,
  ROUND(SAFE_DIVIDE(SUM(asked_then_answered), SUM(asked_in_30d)) * 100, 4)
                                                                       AS pct_asked_then_answered
FROM per_user_flags
GROUP BY month_start
ORDER BY month_start;