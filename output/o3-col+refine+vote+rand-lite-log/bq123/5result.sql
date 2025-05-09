WITH first_answer AS (
  -- find the earliest answer (if any) for every question
  SELECT
    q.id                          AS question_id,
    q.creation_date               AS question_time,
    MIN(a.creation_date)          AS answer_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` a
         ON a.parent_id = q.id
  GROUP BY question_id, question_time
),
day_stats AS (
  -- flag whether the question was answered within 60 minutes, aggregate by weekday
  SELECT
    EXTRACT(DAYOFWEEK FROM question_time)                                       AS dow,        -- 1-Sun … 7-Sat
    SUM(
      CASE
        WHEN answer_time IS NOT NULL
             AND TIMESTAMP_DIFF(answer_time, question_time, MINUTE) <= 60
        THEN 1 ELSE 0
      END
    )                                                                           AS answered_in_hour,
    COUNT(*)                                                                    AS total_q
  FROM first_answer
  GROUP BY dow
),
ranked AS (
  -- compute percentages and rank weekdays
  SELECT
    dow,
    SAFE_DIVIDE(answered_in_hour, total_q)                                      AS pct,
    ROW_NUMBER() OVER (ORDER BY SAFE_DIVIDE(answered_in_hour, total_q) DESC)    AS rn
  FROM day_stats
)
-- pick the weekday in 3rd place
SELECT
  CASE dow
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
  END                                   AS weekday,
  ROUND(pct * 100, 4)                   AS percent_answered_within_hour
FROM ranked
WHERE rn = 3;