WITH user_activity AS (
  SELECT
    u.id AS user_id,
    DATE_TRUNC(DATE(u.creation_date), MONTH) AS Month,
    COUNTIF(pq.id IS NOT NULL) > 0 AS asked_question_within_30_days,
    COUNTIF(pa.id IS NOT NULL) > 0 AS answered_question_within_30_days
  FROM
    `bigquery-public-data.stackoverflow.users` u
  LEFT JOIN
    `bigquery-public-data.stackoverflow.posts_questions` pq
    ON u.id = pq.owner_user_id
    AND pq.creation_date BETWEEN u.creation_date AND TIMESTAMP_ADD(u.creation_date, INTERVAL 30 DAY)
  LEFT JOIN
    `bigquery-public-data.stackoverflow.posts_answers` pa
    ON u.id = pa.owner_user_id
    AND pa.creation_date BETWEEN u.creation_date AND TIMESTAMP_ADD(u.creation_date, INTERVAL 30 DAY)
  WHERE
    DATE(u.creation_date) BETWEEN '2021-01-01' AND '2021-12-31'
  GROUP BY
    user_id, Month
)
SELECT
  FORMAT_DATE('%B %Y', Month) AS Month,
  COUNT(DISTINCT user_id) AS Total_new_users,
  ROUND(SAFE_DIVIDE(
    SUM(CASE WHEN asked_question_within_30_days THEN 1 ELSE 0 END),
    COUNT(DISTINCT user_id)
  ) * 100, 4) AS Percentage_asked_questions,
  ROUND(SAFE_DIVIDE(
    SUM(CASE WHEN asked_question_within_30_days AND answered_question_within_30_days THEN 1 ELSE 0 END),
    COUNT(DISTINCT user_id)
  ) * 100, 4) AS Percentage_asked_and_answered_within_30_days
FROM
  user_activity
GROUP BY
  Month
ORDER BY
  PARSE_DATE('%B %Y', Month)