-- Questions asked in 2021 and how many were answered within 1 hour,
-- aggregated by day of week (Sunday‑Saturday)
WITH q2021 AS (
  SELECT
    id AS question_id,
    creation_date,
    EXTRACT(DAYOFWEEK FROM creation_date) AS dow          -- 1=SUN … 7=SAT
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date >= '2021-01-01' 
    AND creation_date <  '2022-01-01'
),
answered_1h AS (
  -- questions that received at least one answer within 60 minutes
  SELECT DISTINCT q.question_id
  FROM q2021 AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.parent_id = q.question_id
   AND a.creation_date <= TIMESTAMP_ADD(q.creation_date, INTERVAL 1 HOUR)
)
SELECT
  dow,
  CASE dow
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
  END                                                    AS day_of_week,
  COUNT(*)                                               AS total_questions,
  COUNTIF(ans.question_id IS NOT NULL)                  AS answered_within_1h,
  ROUND(
    COUNTIF(ans.question_id IS NOT NULL) / COUNT(*) * 100,
    4
  )                                                     AS pct_answered_within_1h
FROM q2021 AS q
LEFT JOIN answered_1h AS ans
       ON ans.question_id = q.question_id
GROUP BY dow
ORDER BY dow;