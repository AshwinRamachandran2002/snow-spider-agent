WITH question_times AS (
  SELECT
    id AS question_id,
    creation_date AS question_time,
    FORMAT_TIMESTAMP('%A', creation_date) AS weekday
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),
answer_times AS (
  SELECT
    parent_id AS question_id,
    MIN(creation_date) AS answer_time
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),
per_question AS (
  SELECT
    q.weekday,
    IF(
      a.answer_time IS NOT NULL
      AND TIMESTAMP_DIFF(a.answer_time, q.question_time, SECOND) <= 3600,
      1,
      0
    ) AS answered_within_hour
  FROM question_times q
  LEFT JOIN answer_times a
    ON q.question_id = a.question_id
),
stats AS (
  SELECT
    weekday,
    COUNT(*) AS total_questions,
    SUM(answered_within_hour) AS within_hour_count,
    SAFE_DIVIDE(SUM(answered_within_hour), COUNT(*)) * 100 AS pct_within_hour
  FROM per_question
  GROUP BY weekday
)
SELECT
  weekday,
  ROUND(pct_within_hour, 4) AS percentage_within_hour
FROM stats
ORDER BY pct_within_hour DESC, weekday
LIMIT 1 OFFSET 2;      -- third‑highest percentage