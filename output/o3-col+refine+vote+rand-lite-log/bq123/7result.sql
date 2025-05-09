WITH first_answers AS (
  -- find the timestamp of the earliest answer to every question
  SELECT
    q.id                    AS question_id,
    q.creation_date         AS question_time,
    MIN(a.creation_date)    AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.parent_id = q.id
  GROUP BY question_id, question_time
),
stats AS (
  -- for each weekday calculate totals and “answered within an hour”
  SELECT
    FORMAT_TIMESTAMP('%A', question_time) AS weekday,
    COUNT(*)                              AS total_questions,
    COUNTIF(first_answer_time IS NOT NULL
            AND first_answer_time <= question_time + INTERVAL 1 HOUR)
                                           AS answered_within_hour
  FROM first_answers
  GROUP BY weekday
),
ranked AS (
  -- compute the percentage and rank weekdays by that percentage
  SELECT
    weekday,
    SAFE_DIVIDE(answered_within_hour, total_questions) * 100 AS pct_within_hour,
    ROW_NUMBER() OVER (ORDER BY SAFE_DIVIDE(answered_within_hour, total_questions) DESC) AS rn
  FROM stats
)
-- return the weekday with the 3rd-highest percentage
SELECT
  weekday,
  ROUND(pct_within_hour, 4) AS pct_within_hour
FROM ranked
WHERE rn = 3;