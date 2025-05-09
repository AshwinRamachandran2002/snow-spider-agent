WITH first_answers AS (
  -- earliest answer time for each question
  SELECT
    parent_id AS question_id,
    MIN(creation_date) AS first_answer_date
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),
question_stats AS (
  -- attach earliest‑answer info to every question
  SELECT
    FORMAT_TIMESTAMP('%A', q.creation_date) AS day_name,
    CASE
      WHEN fa.first_answer_date IS NOT NULL
           AND TIMESTAMP_DIFF(fa.first_answer_date, q.creation_date, MINUTE) <= 60
      THEN 1 ELSE 0 END AS answered_within_hour
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN first_answers AS fa
  ON fa.question_id = q.id
),
day_agg AS (
  -- percentage of questions answered within an hour for each week‑day
  SELECT
    day_name,
    COUNT(*) AS total_questions,
    SUM(answered_within_hour) AS within_hour,
    SAFE_DIVIDE(SUM(answered_within_hour), COUNT(*)) * 100 AS pct_within_hour
  FROM question_stats
  GROUP BY day_name
),
ranked AS (
  -- rank days by that percentage
  SELECT
    day_name,
    pct_within_hour,
    ROW_NUMBER() OVER (ORDER BY pct_within_hour DESC, day_name) AS rn
  FROM day_agg
)
-- third‑highest day and its percentage
SELECT
  day_name,
  ROUND(pct_within_hour, 4) AS percentage_within_hour
FROM ranked
WHERE rn = 3;