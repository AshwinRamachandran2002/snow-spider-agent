WITH first_answers AS (
  -- earliest answer for every question
  SELECT
    parent_id AS question_id,
    MIN(creation_date) AS first_answer_date
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE parent_id IS NOT NULL
  GROUP BY parent_id
),
question_stats AS (
  -- flag questions whose first answer arrived within 1 hour
  SELECT
    q.id                                           AS question_id,
    EXTRACT(DAYOFWEEK FROM q.creation_date)        AS dow,           -- 1 = Sunday … 7 = Saturday
    CASE
      WHEN f.first_answer_date IS NOT NULL
           AND TIMESTAMP_DIFF(f.first_answer_date, q.creation_date, SECOND) <= 3600
      THEN 1 ELSE 0
    END                                            AS answered_within_hour
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  LEFT JOIN first_answers f
         ON f.question_id = q.id
),
day_percentages AS (
  SELECT
    dow,
    COUNT(*)                                       AS total_questions,
    SUM(answered_within_hour)                      AS answered_in_hour,
    SAFE_DIVIDE(SUM(answered_within_hour), COUNT(*)) * 100 AS pct_within_hour
  FROM question_stats
  GROUP BY dow
),
ranked AS (
  SELECT
    dow,
    pct_within_hour,
    DENSE_RANK() OVER (ORDER BY pct_within_hour DESC) AS rnk
  FROM day_percentages
)
SELECT
  CASE dow
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
  END AS day_of_week,
  ROUND(pct_within_hour, 4) AS percentage_within_hour
FROM ranked
WHERE rnk = 3;