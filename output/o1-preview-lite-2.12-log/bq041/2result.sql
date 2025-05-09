WITH new_users AS (
    SELECT id AS user_id,
           creation_date AS user_creation_date,
           EXTRACT(MONTH FROM creation_date) AS month,
           EXTRACT(YEAR FROM creation_date) AS year
    FROM `bigquery-public-data.stackoverflow.users`
    WHERE creation_date BETWEEN '2021-01-01' AND '2021-12-31'
),
users_with_questions AS (
    SELECT DISTINCT u.user_id, u.month, u.user_creation_date
    FROM new_users u
    JOIN `bigquery-public-data.stackoverflow.posts_questions` pq
      ON u.user_id = pq.owner_user_id
      AND pq.creation_date <= TIMESTAMP_ADD(u.user_creation_date, INTERVAL 30 DAY)
),
users_with_questions_and_answers AS (
    SELECT DISTINCT u.user_id, u.month
    FROM users_with_questions u
    JOIN `bigquery-public-data.stackoverflow.posts_answers` pa
      ON u.user_id = pa.owner_user_id
      AND pa.creation_date <= TIMESTAMP_ADD(u.user_creation_date, INTERVAL 30 DAY)
)
SELECT
    FORMAT_DATE('%B %Y', DATE(u.year, u.month, 1)) AS Month,
    COUNT(DISTINCT u.user_id) AS Total_new_users,
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT qwq.user_id), COUNT(DISTINCT u.user_id)) * 100, 4) AS Percentage_asked_questions,
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT qwa.user_id), COUNT(DISTINCT u.user_id)) * 100, 4) AS Percentage_asked_and_answered_within_30_days
FROM new_users u
LEFT JOIN users_with_questions qwq ON u.user_id = qwq.user_id
LEFT JOIN users_with_questions_and_answers qwa ON u.user_id = qwa.user_id
GROUP BY u.year, u.month
ORDER BY u.year, u.month;