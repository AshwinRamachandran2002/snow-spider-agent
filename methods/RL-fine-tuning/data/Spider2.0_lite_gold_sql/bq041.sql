WITH total_users AS (
  SELECT
    EXTRACT(MONTH FROM u.creation_date) AS month,
    COUNT(*) AS total_new_users
  FROM `bigquery-public-data.stackoverflow.users` u
  WHERE u.creation_date BETWEEN '2021-01-01' AND '2021-12-31'
  GROUP BY month
),

users_who_asked AS (
  SELECT
    EXTRACT(MONTH FROM u.creation_date) AS month,
    COUNT(DISTINCT u.id) AS users_who_asked_questions
  FROM `bigquery-public-data.stackoverflow.users` u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` pq
    ON u.id = pq.owner_user_id
    AND pq.creation_date BETWEEN u.creation_date AND TIMESTAMP_ADD(u.creation_date, INTERVAL 30 DAY)
  WHERE u.creation_date BETWEEN '2021-01-01' AND '2021-12-31'
  GROUP BY month
),

users_asked_and_answered AS (
  SELECT
    EXTRACT(MONTH FROM u.creation_date) AS month,
    COUNT(DISTINCT u.id) AS users_asked_and_answered_within_30_days
  FROM `bigquery-public-data.stackoverflow.users` u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` pq
    ON u.id = pq.owner_user_id
    AND pq.creation_date BETWEEN u.creation_date AND TIMESTAMP_ADD(u.creation_date, INTERVAL 30 DAY)
  JOIN `bigquery-public-data.stackoverflow.posts_answers` pa
    ON u.id = pa.owner_user_id
    AND pa.creation_date BETWEEN u.creation_date AND TIMESTAMP_ADD(u.creation_date, INTERVAL 30 DAY)
  WHERE u.creation_date BETWEEN '2021-01-01' AND '2021-12-31'
  GROUP BY month
)

SELECT
  FORMAT_DATE('%B %Y', DATE(2021, month, 1)) AS Month,
  total_new_users,
  ROUND(100 * users_who_asked_questions / total_new_users, 4) AS Percentage_asked_questions,
  ROUND(100 * users_asked_and_answered_within_30_days / total_new_users, 4) AS Percentage_asked_and_answered_within_30_days
FROM total_users
LEFT JOIN users_who_asked USING (month)
LEFT JOIN users_asked_and_answered USING (month)
ORDER BY month;