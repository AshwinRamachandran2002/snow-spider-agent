WITH signups AS (
  -- all users who registered in 2021
  SELECT
    id AS user_id,
    creation_date AS signup_ts
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),
first_question AS (
  -- first question asked within 30 days of sign-up (if any)
  SELECT
    s.user_id,
    s.signup_ts,
    MIN(q.creation_date) AS first_question_ts
  FROM signups AS s
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.owner_user_id = s.user_id
   AND q.creation_date <= TIMESTAMP_ADD(s.signup_ts, INTERVAL 30 DAY)
  GROUP BY s.user_id, s.signup_ts
),
activity AS (
  -- flag asking within 30 days and answering within 30 days after first question
  SELECT
    fq.user_id,
    fq.signup_ts,
    fq.first_question_ts,
    IF(fq.first_question_ts IS NULL, 0, 1) AS asked_in_30,
    IF(
      fq.first_question_ts IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
        WHERE a.owner_user_id = fq.user_id
          AND a.creation_date  > fq.first_question_ts
          AND a.creation_date <= TIMESTAMP_ADD(fq.first_question_ts, INTERVAL 30 DAY)
      ),
      1, 0
    ) AS answered_after_ask
  FROM first_question AS fq
)
-- monthly aggregation
SELECT
  FORMAT_DATE('%Y-%m', DATE(signup_ts))                                  AS month,
  COUNT(*)                                                               AS new_users,
  ROUND(100 * SAFE_DIVIDE(SUM(asked_in_30), COUNT(*)), 4)                AS pct_asked_within_30,
  ROUND(
    100 * SAFE_DIVIDE(
      SUM(CASE WHEN asked_in_30 = 1 THEN answered_after_ask END),
      NULLIF(SUM(asked_in_30), 0)
    ),
    4
  )                                                                      AS pct_answered_after_ask
FROM activity
GROUP BY month
ORDER BY month;