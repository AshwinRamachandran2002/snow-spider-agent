WITH per_question AS (
  SELECT
    q.id                               AS question_id,
    q.creation_date                    AS question_time,
    FORMAT_TIMESTAMP('%A', q.creation_date) AS weekday_name,
    MIN(a.creation_date)               AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` a
         ON a.parent_id = q.id
  GROUP BY question_id, question_time, weekday_name
),
per_day AS (
  SELECT
    weekday_name,
    COUNT(*) AS total_questions,
    SUM(CASE
          WHEN first_answer_time IS NOT NULL
           AND TIMESTAMP_DIFF(first_answer_time, question_time, SECOND) <= 3600
          THEN 1 ELSE 0 END) AS answered_in_hour
  FROM per_question
  GROUP BY weekday_name
),
percentages AS (
  SELECT
    weekday_name,
    ROUND(SAFE_DIVIDE(answered_in_hour, total_questions) * 100, 4) AS pct_in_hour
  FROM per_day
)
SELECT weekday_name, pct_in_hour
FROM (
  SELECT
    weekday_name,
    pct_in_hour,
    ROW_NUMBER() OVER (ORDER BY pct_in_hour DESC, weekday_name) AS rn
  FROM percentages
)
WHERE rn = 3;