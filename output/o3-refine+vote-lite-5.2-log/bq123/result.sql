WITH first_answers AS (
  SELECT
    parent_id AS question_id,
    MIN(creation_date) AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),
question_with_answer AS (
  SELECT
    q.id AS question_id,
    q.creation_date AS question_time,
    fa.first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN first_answers AS fa
  ON fa.question_id = q.id
),
daily_stats AS (
  SELECT
    FORMAT_TIMESTAMP('%A', question_time) AS day_of_week,
    COUNT(*) AS total_questions,
    SUM(
      CASE
        WHEN first_answer_time IS NOT NULL
             AND TIMESTAMP_DIFF(first_answer_time, question_time, SECOND) <= 3600
        THEN 1 ELSE 0
      END
    ) AS answered_within_hour
  FROM question_with_answer
  GROUP BY day_of_week
),
percentages AS (
  SELECT
    day_of_week,
    ROUND(100.0 * answered_within_hour / total_questions, 4) AS pct_within_hour
  FROM daily_stats
)
SELECT
  day_of_week,
  pct_within_hour
FROM percentages
ORDER BY pct_within_hour DESC, day_of_week
LIMIT 1 OFFSET 2;