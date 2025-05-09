-- Questions asked in 2021 by day‑of‑week, and how many got an answer within 1 hour
WITH questions_2021 AS (        -- all Stack Overflow questions created in 2021
  SELECT
    id                       AS question_id,
    creation_date            AS question_ts,
    EXTRACT(DAYOFWEEK FROM creation_date)                 AS dow_num,   -- 1 = Sunday … 7 = Saturday
    FORMAT_DATE('%A', DATE(creation_date))                AS dow_name
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE DATE(creation_date) BETWEEN '2021-01-01' AND '2021-12-31'
),

first_answers AS (             -- first answer for every question (any year)
  SELECT
    parent_id                 AS question_id,
    MIN(creation_date)        AS first_answer_ts
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE parent_id IS NOT NULL
  GROUP BY parent_id
),

q_ans AS (                     -- join questions with their first answer (if any)
  SELECT
    q.dow_num,
    q.dow_name,
    q.question_id,
    -- 1 if answered within 1 hour, else 0
    IF(first_answer_ts IS NOT NULL
       AND TIMESTAMP_DIFF(first_answer_ts, q.question_ts, SECOND) <= 3600, 1, 0)
       AS answered_within_hour
  FROM questions_2021 q
  LEFT JOIN first_answers a
  ON q.question_id = a.question_id
)

SELECT
  dow_name                                      AS day_of_week,
  COUNT(*)                                      AS total_questions,
  SUM(answered_within_hour)                     AS answered_within_1h,
  ROUND(SAFE_DIVIDE(SUM(answered_within_hour), COUNT(*)) * 100, 4)
                                                AS pct_answered_within_1h
FROM q_ans
GROUP BY day_of_week, dow_num
ORDER BY dow_num;