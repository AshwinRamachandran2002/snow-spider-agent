--  Questions asked in 2021, their weekday, and whether they got
--  at least one answer within the first hour after being posted
WITH questions_2021 AS (
  SELECT
    q.id,
    q.creation_date,
    FORMAT_TIMESTAMP('%A', q.creation_date)         AS weekday_name,     -- e.g. Monday
    EXTRACT(DAYOFWEEK  FROM q.creation_date)        AS weekday_num       -- 1=Sunday … 7=Saturday
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE EXTRACT(YEAR FROM q.creation_date) = 2021
),

first_answers AS (        -- first answer (if any) for every question
  SELECT
    a.parent_id                           AS question_id,
    MIN(a.creation_date)                  AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  GROUP BY a.parent_id
),

q_with_flag AS (
  SELECT
    q.weekday_name,
    q.weekday_num,
    CASE
      WHEN fa.first_answer_time IS NOT NULL
           AND fa.first_answer_time <= q.creation_date + INTERVAL 1 HOUR
      THEN 1
      ELSE 0
    END                                      AS answered_in_1h
  FROM questions_2021 AS q
  LEFT JOIN first_answers AS fa
    ON fa.question_id = q.id
)

SELECT
  weekday_name                                           AS day_of_week,
  COUNT(*)                                               AS total_questions,
  SUM(answered_in_1h)                                    AS answered_in_1h,
  ROUND(SAFE_DIVIDE(SUM(answered_in_1h), COUNT(*))*100,2) AS answered_pct
FROM q_with_flag
GROUP BY weekday_name, weekday_num
ORDER BY weekday_num;