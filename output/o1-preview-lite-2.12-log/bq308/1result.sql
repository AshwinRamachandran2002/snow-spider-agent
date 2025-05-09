WITH questions AS (
  SELECT
    id,
    creation_date,
    EXTRACT(DAYOFWEEK FROM creation_date) AS day_of_week_num
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`
  WHERE
    creation_date BETWEEN '2021-01-01' AND '2021-12-31'
),
questions_with_answered_flag AS (
  SELECT
    q.id,
    q.day_of_week_num,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM `bigquery-public-data.stackoverflow.posts_answers` a
        WHERE a.parent_id = q.id
          AND a.creation_date BETWEEN q.creation_date AND TIMESTAMP_ADD(q.creation_date, INTERVAL 1 HOUR)
      ) THEN 1
      ELSE 0
    END AS answered_within_one_hour
  FROM
    questions q
)
SELECT
  CASE day_of_week_num
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
  END AS Day_of_week,
  COUNT(*) AS Questions_Asked,
  SUM(answered_within_one_hour) AS Questions_Answered_Within_One_Hour,
  ROUND(SUM(answered_within_one_hour) / COUNT(*) * 100, 4) AS Percentage_Answered_Within_One_Hour
FROM
  questions_with_answered_flag
GROUP BY
  day_of_week_num
ORDER BY
  day_of_week_num;