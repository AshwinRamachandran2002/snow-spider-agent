WITH new_users AS (
  SELECT
    id                                           AS user_id,
    creation_date                                AS signup_ts,
    FORMAT_DATE('%Y-%m', DATE(creation_date))    AS month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),

first_q_30d AS (   -- first question asked within 30-days of sign-up
  SELECT
    n.user_id,
    MIN(q.creation_date) AS first_q_ts
  FROM new_users n
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
       ON q.owner_user_id = n.user_id
      AND q.creation_date BETWEEN n.signup_ts
                              AND TIMESTAMP_ADD(n.signup_ts, INTERVAL 30 DAY)
  GROUP BY n.user_id
),

answered_30d AS (   -- answered after that question and within the next 30-days
  SELECT DISTINCT a.owner_user_id AS user_id
  FROM first_q_30d f
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
       ON a.owner_user_id = f.user_id
      AND a.creation_date >  f.first_q_ts
      AND a.creation_date <= TIMESTAMP_ADD(f.first_q_ts, INTERVAL 30 DAY)
)

SELECT
  n.month,
  COUNT(*)                                                   AS new_users,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT f.user_id), COUNT(*)), 2)
                                                             AS pct_asked_30d,
  ROUND(
        100 * SAFE_DIVIDE(COUNT(DISTINCT ans.user_id),
                          NULLIF(COUNT(DISTINCT f.user_id),0)), 2)
                                                             AS pct_answered_after_q_30d
FROM new_users n
LEFT JOIN first_q_30d   f   ON f.user_id  = n.user_id
LEFT JOIN answered_30d  ans ON ans.user_id = n.user_id
GROUP BY n.month
ORDER BY n.month;