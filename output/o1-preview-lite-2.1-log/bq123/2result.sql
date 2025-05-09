WITH total_questions_per_day AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM creation_date) AS day_of_week,
    COUNT(*) AS total_questions
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`
  GROUP BY
    day_of_week
),
questions_answered_within_hour AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM q.creation_date) AS day_of_week,
    COUNT(DISTINCT q.id) AS questions_answered_within_hour
  FROM
    `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN
    `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON q.id = a.parent_id
  WHERE
    TIMESTAMP_DIFF(a.creation_date, q.creation_date, MINUTE) <= 60
  GROUP BY
    day_of_week
)
SELECT
  FORMAT_DATE('%A', DATE_ADD(DATE '1970-01-04', INTERVAL total.day_of_week - 1 DAY)) AS Day,
  ROUND((answered.questions_answered_within_hour / total.total_questions) * 100, 4) AS Percentage
FROM
  total_questions_per_day AS total
JOIN
  questions_answered_within_hour AS answered
  ON total.day_of_week = answered.day_of_week
ORDER BY
  Percentage DESC,
  total.day_of_week
LIMIT 1
OFFSET 2;