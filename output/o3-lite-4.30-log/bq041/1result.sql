WITH new_users AS (
  SELECT
    id AS user_id,
    creation_date AS signup_ts,
    FORMAT_DATE('%Y-%m', DATE_TRUNC(DATE(creation_date), MONTH)) AS month
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE DATE(creation_date) BETWEEN '2021-01-01' AND '2021-12-31'
),

asked_within_30d AS (
  SELECT DISTINCT u.id AS user_id
  FROM `bigquery-public-data.stackoverflow.users`           AS u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.owner_user_id = u.id
  WHERE DATE(u.creation_date) BETWEEN '2021-01-01' AND '2021-12-31'
    AND TIMESTAMP_DIFF(q.creation_date, u.creation_date, DAY) BETWEEN 0 AND 30
),

first_question AS (
  SELECT
    u.id AS user_id,
    MIN(q.creation_date) AS first_question_ts
  FROM `bigquery-public-data.stackoverflow.users`           AS u
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.owner_user_id = u.id
  WHERE DATE(u.creation_date) BETWEEN '2021-01-01' AND '2021-12-31'
    AND TIMESTAMP_DIFF(q.creation_date, u.creation_date, DAY) BETWEEN 0 AND 30
  GROUP BY user_id
),

answered_after_question_30d AS (
  SELECT DISTINCT fq.user_id
  FROM first_question AS fq
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.owner_user_id = fq.user_id
  WHERE a.creation_date > fq.first_question_ts
    AND TIMESTAMP_DIFF(a.creation_date, fq.first_question_ts, DAY) BETWEEN 0 AND 30
)

SELECT
  nu.month,
  COUNT(*) AS total_new_users,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(nu.user_id IN (SELECT user_id FROM asked_within_30d)),
      COUNT(*)
    ) * 100, 4
  ) AS pct_asked_within_30d,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(nu.user_id IN (SELECT user_id FROM answered_after_question_30d)),
      NULLIF(COUNTIF(nu.user_id IN (SELECT user_id FROM asked_within_30d)), 0)
    ) * 100, 4
  ) AS pct_answer_after_ask_within_30d
FROM new_users AS nu
GROUP BY nu.month
ORDER BY nu.month;