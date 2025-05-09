WITH users_2021 AS (
  SELECT
    id,
    creation_date,
    FORMAT_DATE('%Y-%m', DATE(creation_date)) AS month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE DATE(creation_date) BETWEEN '2021-01-01' AND '2021-12-31'
),
first_question AS (
  SELECT
    owner_user_id,
    MIN(creation_date) AS first_question_date
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  GROUP BY owner_user_id
),
askers AS (
  SELECT
    u.id AS user_id,
    u.month,
    fq.first_question_date
  FROM users_2021 AS u
  JOIN first_question AS fq
    ON fq.owner_user_id = u.id
  WHERE fq.first_question_date < u.creation_date + INTERVAL 30 DAY
),
answerers AS (
  SELECT DISTINCT
    a.owner_user_id AS user_id
  FROM askers AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.owner_user_id = q.user_id
   AND a.creation_date BETWEEN q.first_question_date
                           AND q.first_question_date + INTERVAL 30 DAY
   AND a.creation_date > q.first_question_date
)
SELECT
  u.month,
  COUNT(*) AS total_new_users,
  ROUND(100 * COUNT(DISTINCT a.user_id) / COUNT(*), 4) AS pct_asked_within_30d,
  ROUND(
    100 * COUNT(DISTINCT an.user_id)
        / NULLIF(COUNT(DISTINCT a.user_id), 0),
    4
  ) AS pct_answer_after_ask_within_30d
FROM users_2021 AS u
LEFT JOIN askers    AS a  ON a.user_id  = u.id
LEFT JOIN answerers AS an ON an.user_id = u.id
GROUP BY u.month
ORDER BY u.month;