WITH questions_2021 AS (
  SELECT
    id,
    creation_date,
    FORMAT_TIMESTAMP('%A', creation_date)               AS day_name,     -- Monday … Sunday
    EXTRACT(DAYOFWEEK FROM creation_date)               AS dow           -- 1‑Sunday … 7‑Saturday
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),

-- questions that received at least one answer within one hour
answered_within_hour AS (
  SELECT DISTINCT
    q.id,
    q.day_name,
    q.dow
  FROM questions_2021 q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON a.parent_id = q.id
   AND a.creation_date <= TIMESTAMP_ADD(q.creation_date, INTERVAL 1 HOUR)
),

-- total questions per weekday
totals AS (
  SELECT
    day_name,
    dow,
    COUNT(*) AS total_questions
  FROM questions_2021
  GROUP BY day_name, dow
),

-- how many of those were answered within one hour
fast AS (
  SELECT
    day_name,
    dow,
    COUNT(*) AS answered_within_1h
  FROM answered_within_hour
  GROUP BY day_name, dow
)

SELECT
  t.day_name,
  t.total_questions,
  IFNULL(f.answered_within_1h, 0)                                        AS answered_within_1h,
  ROUND(IFNULL(f.answered_within_1h, 0) / t.total_questions * 100, 2)    AS pct_answered_within_1h
FROM totals t
LEFT JOIN fast f USING (day_name, dow)
ORDER BY t.dow;   -- Sunday (1) … Saturday (7)