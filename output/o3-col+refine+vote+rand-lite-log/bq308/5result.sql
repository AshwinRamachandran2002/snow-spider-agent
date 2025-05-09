-- Questions vs. “answered within 1-hour” by day-of-week for calendar-year 2021
WITH questions_2021 AS (
  SELECT
    id,
    creation_date,
    EXTRACT(DAYOFWEEK FROM creation_date) AS dow_num            -- 1=Sun … 7=Sat
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE DATE(creation_date) BETWEEN '2021-01-01' AND '2021-12-31'
),

-- first answer time for each question that actually got an answer
first_answers AS (
  SELECT
    q.id,
    MIN(a.creation_date) AS first_answer_time
  FROM questions_2021 AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.parent_id = q.id
  GROUP BY q.id
),

-- questions whose first answer arrived ≤ 60 minutes after the question
fast_answers AS (
  SELECT
    q.id
  FROM questions_2021 AS q
  JOIN first_answers  AS fa ON fa.id = q.id
  WHERE TIMESTAMP_DIFF(fa.first_answer_time, q.creation_date, MINUTE) <= 60
)

SELECT
  q.dow_num,
  FORMAT_DATE('%A', DATE '2021-08-01' + q.dow_num - 1)         AS day_of_week,
  COUNT(*)                                                     AS total_questions,
  COUNT(fa.id)                                                 AS answered_within_1h,
  ROUND(100 * COUNT(fa.id) / COUNT(*), 2)                      AS pct_answered_within_1h
FROM questions_2021 AS q
LEFT JOIN fast_answers AS fa
  ON fa.id = q.id
GROUP BY dow_num
ORDER BY dow_num;