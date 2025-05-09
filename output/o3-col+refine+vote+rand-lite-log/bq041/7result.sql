-- Monthly statistics for new 2021 users
WITH new_users AS (
  SELECT
    id AS user_id,
    creation_date AS signup_date
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),
first_question AS (
  SELECT
    u.user_id,
    MIN(q.creation_date) AS first_question_date
  FROM new_users AS u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.owner_user_id = u.user_id
   AND q.creation_date BETWEEN u.signup_date
                           AND u.signup_date + INTERVAL 30 DAY
  GROUP BY u.user_id
),
answers_after_question AS (
  SELECT DISTINCT
    f.user_id
  FROM first_question AS f
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.owner_user_id = f.user_id
   AND a.creation_date BETWEEN f.first_question_date
                           AND f.first_question_date + INTERVAL 30 DAY
)
SELECT
  EXTRACT(MONTH FROM u.signup_date)               AS month,
  COUNT(*)                                        AS total_new_users,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT f.user_id), COUNT(*)), 4)
                                                  AS pct_asked_within_30,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT aa.user_id),
                          COUNT(DISTINCT f.user_id)), 4)
                                                  AS pct_answered_after_question
FROM new_users AS u
LEFT JOIN first_question        AS f  ON f.user_id  = u.user_id
LEFT JOIN answers_after_question AS aa ON aa.user_id = u.user_id
GROUP BY month
ORDER BY month;