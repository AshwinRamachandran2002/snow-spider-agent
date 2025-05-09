WITH new_users_2021 AS (
  SELECT
    id                                   AS user_id,
    creation_date,
    FORMAT_DATE('%Y-%m', DATE(creation_date)) AS month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE DATE(creation_date) BETWEEN '2021-01-01' AND '2021-12-31'
),

early_questions AS (
  SELECT
    nu.user_id,
    nu.month,
    MIN(pq.creation_date) AS first_question_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS pq
  JOIN new_users_2021 AS nu
    ON pq.owner_user_id = nu.user_id
  WHERE pq.creation_date BETWEEN nu.creation_date
                             AND TIMESTAMP_ADD(nu.creation_date, INTERVAL 30 DAY)
  GROUP BY nu.user_id, nu.month
),

early_answers AS (
  SELECT DISTINCT
    eq.user_id,
    eq.month
  FROM early_questions AS eq
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS pa
    ON pa.owner_user_id = eq.user_id
  WHERE pa.creation_date >  eq.first_question_time
    AND pa.creation_date <= TIMESTAMP_ADD(eq.first_question_time, INTERVAL 30 DAY)
)

SELECT
  nu.month                                            AS month,
  COUNT(DISTINCT nu.user_id)                          AS total_new_users,
  ROUND(100 * COUNT(DISTINCT eq.user_id)
            / COUNT(DISTINCT nu.user_id), 4)          AS pct_asked_within_30d,
  ROUND(100 * COUNT(DISTINCT ea.user_id)
            / NULLIF(COUNT(DISTINCT eq.user_id), 0), 4)
                                                    AS pct_answer_after_ask_within_30d
FROM new_users_2021 AS nu
LEFT JOIN early_questions AS eq ON eq.user_id = nu.user_id
LEFT JOIN early_answers  AS ea ON ea.user_id = nu.user_id
GROUP BY nu.month
ORDER BY nu.month;