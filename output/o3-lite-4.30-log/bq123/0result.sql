WITH first_answers AS (
  SELECT
    parent_id,
    MIN(creation_date) AS first_answer_ts
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE parent_id IS NOT NULL
  GROUP BY parent_id
),
daily_stats AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM q.creation_date) AS day_of_week,
    COUNT(*) AS total_questions,
    COUNTIF(
      TIMESTAMP_DIFF(f.first_answer_ts, q.creation_date, MINUTE) <= 60
    ) AS answered_within_hour
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN first_answers AS f
    ON q.id = f.parent_id
  GROUP BY day_of_week
),
ranked AS (
  SELECT
    day_of_week,
    SAFE_DIVIDE(answered_within_hour, total_questions) AS percentage,
    DENSE_RANK() OVER (
      ORDER BY SAFE_DIVIDE(answered_within_hour, total_questions) DESC
    ) AS rnk
  FROM daily_stats
)
SELECT
  day_of_week,
  ROUND(percentage, 4) AS percentage
FROM ranked
WHERE rnk = 3;