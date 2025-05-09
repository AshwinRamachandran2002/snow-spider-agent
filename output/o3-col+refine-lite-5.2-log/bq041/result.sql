-- Monthly statistics for 2021 sign‑ups
WITH new_users AS (
  SELECT
    id                             AS user_id,
    creation_date,
    EXTRACT(MONTH FROM creation_date) AS month_2021
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR  FROM creation_date) = 2021
),

-- users who asked ≥1 question within 30 days of sign‑up (keep first‑question date)
askers AS (
  SELECT
    u.user_id,
    u.month_2021,
    MIN(q.creation_date) AS first_q_date
  FROM new_users                 AS u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.owner_user_id = u.user_id
   AND q.creation_date < u.creation_date + INTERVAL 30 DAY
  GROUP BY u.user_id, u.month_2021
),

-- among those askers, users who answered ≥1 question after their first question
-- and within the next 30 days
answerers AS (
  SELECT DISTINCT a.user_id
  FROM askers                         AS a
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS ans
    ON ans.owner_user_id = a.user_id
   AND ans.creation_date >  a.first_q_date
   AND ans.creation_date <= a.first_q_date + INTERVAL 30 DAY
)

SELECT
  n.month_2021                       AS month_2021,
  COUNT(*)                           AS new_users,
  SAFE_DIVIDE(
      100 * COUNTIF(ask.user_id IS NOT NULL),
      COUNT(*)
  )                                  AS pct_new_asked30,
  SAFE_DIVIDE(
      100 * COUNTIF(ans.user_id IS NOT NULL),
      COUNTIF(ask.user_id IS NOT NULL)
  )                                  AS pct_askers_answered30
FROM new_users       AS n
LEFT JOIN askers     AS ask ON ask.user_id = n.user_id
LEFT JOIN answerers  AS ans ON ans.user_id = n.user_id
GROUP BY month_2021
ORDER BY month_2021;