WITH questions_2021 AS (
  SELECT
    id,
    creation_date,
    EXTRACT(DAYOFWEEK FROM creation_date) AS dow_num,          -- Sunday = 1 … Saturday = 7
    FORMAT_DATE('%A', DATE(creation_date))    AS weekday_name  -- e.g. 'Monday'
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),

answered_within_1h AS (
  SELECT DISTINCT q.id
  FROM questions_2021 q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON a.parent_id = q.id
   AND a.creation_date <= q.creation_date + INTERVAL 1 HOUR
)

SELECT
  weekday_name                    AS day_of_week,
  COUNT(*)                        AS total_questions,
  COUNT(awh.id)                   AS answered_within_1h,
  ROUND(COUNT(awh.id) / COUNT(*) * 100, 4) AS pct_answered_within_1h
FROM questions_2021 q
LEFT JOIN answered_within_1h awh
       ON awh.id = q.id
GROUP BY
  dow_num,
  weekday_name
ORDER BY
  dow_num;