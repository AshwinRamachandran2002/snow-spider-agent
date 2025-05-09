-- Monthly funnel of 2021 sign-ups → ask within 30 days → answer within 30 days after first question
WITH
-- 1. All users who signed up in 2021
new_users AS (
  SELECT
    id                       AS user_id,
    creation_date            AS signup_ts,
    FORMAT_DATE('%Y-%m', DATE(creation_date)) AS yyyymm
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),

-- 2. First question each of those users asked within 30 days of sign-up
first_questions AS (
  SELECT
    u.user_id,
    MIN(q.creation_date)     AS first_q_ts        -- timestamp of first question
  FROM new_users u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.owner_user_id = u.user_id
   AND q.creation_date <= u.signup_ts + INTERVAL 30 DAY
  GROUP BY u.user_id
),

-- 3. Users who answered at least one question after their first question
--    and within 30 days of that first question
answered_after_q AS (
  SELECT DISTINCT f.user_id
  FROM first_questions f
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON a.owner_user_id = f.user_id
   AND a.creation_date >  f.first_q_ts
   AND a.creation_date <= f.first_q_ts + INTERVAL 30 DAY
)

-- 4. Monthly aggregation and percentage calculations
SELECT
  n.yyyymm                                           AS month,
  COUNT(*)                                           AS new_users,
  ROUND(100 * SAFE_DIVIDE(COUNT(f.user_id), COUNT(*)), 4) AS pct_asked_within_30d,
  ROUND(
        100 * SAFE_DIVIDE(COUNT(a.user_id), NULLIF(COUNT(f.user_id),0))
       , 4)                                          AS pct_answered_after_q_within_30d
FROM new_users n
LEFT JOIN first_questions  f ON f.user_id = n.user_id
LEFT JOIN answered_after_q a ON a.user_id = n.user_id
GROUP BY month
ORDER BY month;