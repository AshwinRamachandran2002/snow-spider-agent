WITH first_answer AS (
  -- earliest answer for every question
  SELECT
    parent_id AS question_id,
    MIN(creation_date) AS first_answer_date
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE parent_id IS NOT NULL
  GROUP BY parent_id
),
question_with_flag AS (
  -- flag questions answered within one hour of being asked
  SELECT
    q.id,
    FORMAT_TIMESTAMP('%A', q.creation_date)          AS weekday,
    IF( fa.first_answer_date IS NOT NULL
        AND TIMESTAMP_DIFF(fa.first_answer_date, q.creation_date, SECOND) BETWEEN 0 AND 3600,
        1, 0)                                        AS answered_in_1h
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  LEFT JOIN first_answer fa
         ON fa.question_id = q.id
),
day_stats AS (
  -- percentage per weekday
  SELECT
    weekday,
    SAFE_DIVIDE(SUM(answered_in_1h), COUNT(*)) * 100 AS pct_within_hour
  FROM question_with_flag
  GROUP BY weekday
)
-- third‑highest percentage of questions answered within an hour
SELECT
  weekday,
  pct_within_hour
FROM day_stats
ORDER BY pct_within_hour DESC, weekday
LIMIT 1 OFFSET 2;