WITH new_users AS (
  SELECT
      id                                   AS user_id,
      creation_date                        AS signup_ts,
      DATE_TRUNC(creation_date, MONTH)     AS month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),

-- users who asked ≥1 question within 30 days of signing-up
asked_within_30 AS (
  SELECT DISTINCT u.user_id
  FROM new_users u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.owner_user_id = u.user_id
  WHERE q.creation_date BETWEEN u.signup_ts
                            AND TIMESTAMP_ADD(u.signup_ts, INTERVAL 30 DAY)
),

-- first question time-stamp (within the 30-day window)
first_question AS (
  SELECT
      u.user_id,
      MIN(q.creation_date) AS first_q_ts
  FROM new_users u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON q.owner_user_id = u.user_id
  WHERE q.creation_date BETWEEN u.signup_ts
                            AND TIMESTAMP_ADD(u.signup_ts, INTERVAL 30 DAY)
  GROUP BY u.user_id
),

-- users who posted ≥1 answer after their first question and
-- within 30 days following that first question
answered_after_q AS (
  SELECT DISTINCT fq.user_id
  FROM first_question fq
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON a.owner_user_id = fq.user_id
  WHERE a.creation_date >  fq.first_q_ts
    AND a.creation_date <= TIMESTAMP_ADD(fq.first_q_ts, INTERVAL 30 DAY)
)

SELECT
    n.month,
    COUNT(*)                                   AS new_users,
    COUNT(DISTINCT aw.user_id)                 AS users_asked_30d,
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT aw.user_id),
                      COUNT(*)) * 100, 4)      AS pct_asked_30d,
    COUNT(DISTINCT aa.user_id)                 AS users_answered_after_q,
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT aa.user_id),
                      NULLIF(COUNT(DISTINCT aw.user_id),0)) * 100, 4)
                                               AS pct_answered_after_q_30d
FROM   new_users           AS n
LEFT   JOIN asked_within_30  aw ON n.user_id = aw.user_id
LEFT   JOIN answered_after_q aa ON n.user_id = aa.user_id
GROUP  BY n.month
ORDER  BY n.month;