WITH first_answer AS (
  -- Earliest answer time for each question
  SELECT
    parent_id AS question_id,
    MIN(creation_date) AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),
question_flags AS (
  -- Flag questions answered inside one hour
  SELECT
    FORMAT_TIMESTAMP('%A', q.creation_date) AS weekday,
    CASE
      WHEN f.first_answer_time IS NOT NULL
           AND TIMESTAMP_DIFF(f.first_answer_time, q.creation_date, SECOND) <= 3600
      THEN 1 ELSE 0
    END AS answered_in_1h
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN first_answer AS f
    ON f.question_id = q.id
),
weekday_stats AS (
  -- Percentage answered within an hour for each weekday
  SELECT
    weekday,
    COUNT(*)                                   AS total_q,
    SUM(answered_in_1h)                        AS answered_1h,
    SAFE_DIVIDE(SUM(answered_in_1h), COUNT(*)) * 100 AS pct_in_1h
  FROM question_flags
  GROUP BY weekday
)
-- Third‑highest percentage
SELECT
  weekday                  AS day_of_week,
  ROUND(pct_in_1h, 4)      AS percent_answered_within_hour
FROM weekday_stats
ORDER BY pct_in_1h DESC, weekday      -- secondary sort for determinism
LIMIT 1 OFFSET 2;                     -- 0‑based offset → third place