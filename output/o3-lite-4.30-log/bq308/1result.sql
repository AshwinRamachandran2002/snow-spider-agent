WITH questions AS (
  SELECT
    id AS question_id,
    creation_date,
    EXTRACT(DAYOFWEEK FROM creation_date) AS dow_num,          -- 1=Sunday … 7=Saturday
    FORMAT_TIMESTAMP('%A', creation_date) AS day_of_week
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date >= '2021-01-01'
    AND creation_date <  '2022-01-01'
),
first_answers AS (
  SELECT
    parent_id AS question_id,
    MIN(creation_date) AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),
combined AS (
  SELECT
    q.day_of_week,
    q.dow_num,
    TIMESTAMP_DIFF(fa.first_answer_time, q.creation_date, MINUTE) AS minutes_to_first_answer
  FROM questions q
  LEFT JOIN first_answers fa
    ON fa.question_id = q.question_id
)
SELECT
  day_of_week,
  COUNT(*)                                 AS total_questions,
  COUNTIF(minutes_to_first_answer <= 60)   AS answered_within_1h,
  ROUND(100 * COUNTIF(minutes_to_first_answer <= 60) / COUNT(*), 4)
                                           AS percent_answered_within_1h
FROM combined
GROUP BY day_of_week, dow_num
ORDER BY dow_num;