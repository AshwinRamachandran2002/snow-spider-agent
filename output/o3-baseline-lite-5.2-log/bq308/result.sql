-- Questions asked in 2021 and whether they received an answer within 1 hour,
-- aggregated by day‑of‑week
WITH questions_2021 AS (
  SELECT
    id,
    creation_date,
    EXTRACT(DAYOFWEEK FROM creation_date) AS dow,                       -- 1 = Sunday … 7 = Saturday
    FORMAT_TIMESTAMP('%A', creation_date)        AS day_name
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),
q_with_flag AS (
  SELECT
    q.day_name,
    q.dow,
    -- flag = 1 if at least one answer arrived within 60 minutes
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM `bigquery-public-data.stackoverflow.posts_answers` a
        WHERE a.parent_id = q.id
          AND a.creation_date <= q.creation_date + INTERVAL 1 HOUR
      ) THEN 1 ELSE 0
    END AS answered_within_hour
  FROM questions_2021 AS q
)

SELECT
  day_name,
  COUNT(*)                                             AS total_questions,
  SUM(answered_within_hour)                            AS questions_answered_within_hour,
  ROUND(100 * SUM(answered_within_hour) / COUNT(*),2)  AS percent_answered_within_hour
FROM q_with_flag
GROUP BY day_name, dow
ORDER BY dow;