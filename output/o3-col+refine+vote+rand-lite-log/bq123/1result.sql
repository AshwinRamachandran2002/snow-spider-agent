WITH earliest_answer AS (
  -- first answer time for each question
  SELECT
    parent_id AS question_id,
    MIN(creation_date) AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),
question_flags AS (
  -- flag questions that got an answer within 1 hour
  SELECT
    FORMAT_TIMESTAMP('%A', q.creation_date) AS weekday,
    CASE
      WHEN ea.first_answer_time IS NOT NULL
           AND TIMESTAMP_DIFF(ea.first_answer_time, q.creation_date, SECOND) <= 3600
      THEN 1 ELSE 0
    END AS fast
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN earliest_answer AS ea
  ON q.id = ea.question_id
),
weekday_stats AS (
  -- percentage of “fast-answered” questions per weekday
  SELECT
    weekday,
    SAFE_DIVIDE(SUM(fast), COUNT(*)) AS pct_fast
  FROM question_flags
  GROUP BY weekday
),
ranked AS (
  -- rank weekdays by that percentage
  SELECT
    weekday,
    pct_fast,
    DENSE_RANK() OVER (ORDER BY pct_fast DESC) AS rnk
  FROM weekday_stats
)
-- day with the 3rd-highest percentage
SELECT weekday, pct_fast
FROM ranked
WHERE rnk = 3;