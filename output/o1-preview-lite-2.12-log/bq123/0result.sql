WITH question_first_answer AS (
  SELECT
    q.id AS question_id,
    q.creation_date AS question_creation_date,
    EXTRACT(DAYOFWEEK FROM q.creation_date) AS question_day_of_week,
    MIN(a.creation_date) AS first_answer_date
  FROM
    `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN
    `bigquery-public-data.stackoverflow.posts_answers` AS a
  ON
    q.id = a.parent_id
  GROUP BY
    q.id, q.creation_date
),
question_time_diff AS (
  SELECT
    *,
    TIMESTAMP_DIFF(first_answer_date, question_creation_date, MINUTE) AS time_to_first_answer_minutes
  FROM
    question_first_answer
),
question_answered_flag AS (
  SELECT
    *,
    CASE
      WHEN time_to_first_answer_minutes <= 60 AND time_to_first_answer_minutes IS NOT NULL THEN 1
      ELSE 0
    END AS answered_within_one_hour
  FROM
    question_time_diff
),
daily_stats AS (
  SELECT
    question_day_of_week,
    COUNT(*) AS total_questions,
    SUM(answered_within_one_hour) AS questions_answered_within_one_hour,
    SAFE_DIVIDE(SUM(answered_within_one_hour), COUNT(*)) * 100 AS percentage_answered_within_one_hour
  FROM
    question_answered_flag
  GROUP BY
    question_day_of_week
),
ranked_days AS (
  SELECT
    question_day_of_week,
    CASE question_day_of_week
      WHEN 1 THEN 'Sunday'
      WHEN 2 THEN 'Monday'
      WHEN 3 THEN 'Tuesday'
      WHEN 4 THEN 'Wednesday'
      WHEN 5 THEN 'Thursday'
      WHEN 6 THEN 'Friday'
      WHEN 7 THEN 'Saturday'
    END AS Day_of_week,
    percentage_answered_within_one_hour,
    ROW_NUMBER() OVER (ORDER BY percentage_answered_within_one_hour DESC) AS rn
  FROM
    daily_stats
)
SELECT
  Day_of_week,
  ROUND(percentage_answered_within_one_hour, 4) AS Percentage
FROM
  ranked_days
WHERE
  rn = 3;