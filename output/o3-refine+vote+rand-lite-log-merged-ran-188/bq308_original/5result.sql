-- Questions asked in 2021, how many (and what share) got an answer within 1 hour,
-- broken down by day‑of‑week
WITH questions_2021 AS (
  SELECT
    id,
    creation_date,
    FORMAT_DATE('%A', DATE(creation_date))               AS day_of_week,
    EXTRACT(DAYOFWEEK FROM DATE(creation_date))          AS day_num        -- Sunday = 1
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`
  WHERE
    creation_date >= '2021-01-01' AND creation_date < '2022-01-01'
),
first_answers AS (
  -- first (earliest) answer each question got
  SELECT
    parent_id                                            AS question_id,
    MIN(creation_date)                                   AS first_answer_time
  FROM
    `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY
    parent_id
),
per_question AS (
  SELECT
    q.day_of_week,
    q.day_num,
    IF(
      fa.first_answer_time IS NOT NULL
      AND TIMESTAMP_DIFF(fa.first_answer_time, q.creation_date, SECOND) <= 3600,
      1, 0
    )                                                   AS answered_within_1h
  FROM
    questions_2021 q
  LEFT JOIN
    first_answers fa
  ON
    q.id = fa.question_id
)
SELECT
  day_of_week,
  COUNT(*)                                            AS total_questions,
  SUM(answered_within_1h)                             AS answered_within_1h,
  ROUND(100 * SUM(answered_within_1h) / COUNT(*), 2)  AS pct_answered_within_1h
FROM
  per_question
GROUP BY
  day_of_week, day_num
ORDER BY
  day_num;   -- Sunday(1) … Saturday(7); adjust if another ordering is preferred