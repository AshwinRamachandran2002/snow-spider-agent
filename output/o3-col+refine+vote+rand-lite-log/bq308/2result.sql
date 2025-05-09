-- Questions asked in 2021, how many got their first answer within 1 hour,
-- aggregated by day-of-week
WITH questions_2021 AS (
  SELECT
    id   AS question_id,
    creation_date AS question_time
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date BETWEEN '2021-01-01' AND '2021-12-31'
),
-- For each 2021 question, find the earliest answer that arrived ≤ 1 hour
first_answers AS (
  SELECT
    q.question_id,
    q.question_time,
    MIN(
      IF(
        a.creation_date <= TIMESTAMP_ADD(q.question_time, INTERVAL 1 HOUR),
        a.creation_date,
        NULL
      )
    ) AS first_answer_time
  FROM questions_2021 q
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON a.parent_id = q.question_id
  GROUP BY q.question_id, q.question_time
)

SELECT
  EXTRACT(DAYOFWEEK FROM question_time)            AS weekday_num,           -- 1=Sun … 7=Sat
  FORMAT_TIMESTAMP('%A', question_time)            AS day_of_week,
  COUNT(*)                                         AS total_questions,
  COUNTIF(first_answer_time IS NOT NULL)           AS answered_within_hour,
  ROUND(
    100 * COUNTIF(first_answer_time IS NOT NULL)
        / COUNT(*), 2)                             AS pct_answered_1hr
FROM first_answers
GROUP BY weekday_num, day_of_week
ORDER BY weekday_num;