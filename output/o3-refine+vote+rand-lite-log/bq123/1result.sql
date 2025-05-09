-- Day of the week with the 3rd‑highest percentage of questions
-- that receive an answer within one hour
WITH first_answers AS (
  SELECT
    parent_id,
    MIN(creation_date) AS first_answer_date
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),
question_flags AS (
  SELECT
    FORMAT_TIMESTAMP('%A', q.creation_date)       AS day_name,
    IF(
      a.first_answer_date IS NOT NULL
      AND TIMESTAMP_DIFF(a.first_answer_date, q.creation_date, SECOND) <= 3600,
      1,                                           -- answered within an hour
      0                                            -- not answered within an hour
    )                                             AS fast_answer_flag
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  LEFT JOIN first_answers a
    ON a.parent_id = q.id
),
day_stats AS (
  SELECT
    day_name,
    COUNT(*)                                      AS total_questions,
    SUM(fast_answer_flag)                         AS fast_answers,
    100.0 * SUM(fast_answer_flag) / COUNT(*)      AS pct_within_hour
  FROM question_flags
  GROUP BY day_name
)
SELECT
  day_name,
  ROUND(pct_within_hour, 4) AS percentage_within_hour
FROM day_stats
ORDER BY pct_within_hour DESC, day_name
LIMIT 1 OFFSET 2;      -- third‑highest percentage