-- Questions per day‑of‑week in 2021 and how many were answered within one hour
WITH questions_2021 AS (        -- all questions asked in 2021
  SELECT
    id                            AS question_id,
    creation_date,
    EXTRACT(DAYOFWEEK FROM creation_date) AS dow        -- 1‑Sun … 7‑Sat
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),
answers AS (                     -- every answer (any year)
  SELECT
    parent_id     AS question_id,
    creation_date
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),
answered_quickly AS (            -- questions that got an answer ≤ 1 hour
  SELECT DISTINCT q.question_id
  FROM questions_2021 q
  JOIN answers a
    ON a.question_id = q.question_id
   AND a.creation_date <= q.creation_date + INTERVAL 1 HOUR
)
SELECT
  dow,
  CASE dow
       WHEN 1 THEN 'Sunday'    WHEN 2 THEN 'Monday'
       WHEN 3 THEN 'Tuesday'   WHEN 4 THEN 'Wednesday'
       WHEN 5 THEN 'Thursday'  WHEN 6 THEN 'Friday'
       WHEN 7 THEN 'Saturday'
  END                          AS day_name,
  COUNT(*)                     AS total_questions,
  COUNT(aw.question_id)        AS answered_within_one_hour,
  ROUND(SAFE_DIVIDE(COUNT(aw.question_id), COUNT(*)) * 100, 4)
                               AS pct_answered_within_one_hour
FROM questions_2021 q
LEFT JOIN answered_quickly aw
       ON q.question_id = aw.question_id
GROUP BY dow, day_name
ORDER BY dow;