-- Questions asked in 2021 and how many got an answer within 1 hour,
-- broken down by day of the week
WITH questions_2021 AS (
  SELECT
    id,
    creation_date,
    EXTRACT(DAYOFWEEK FROM creation_date)            AS dow,            -- 1=Sunday … 7=Saturday
    FORMAT_DATE('%A', DATE(creation_date))           AS day_name
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date >= '2021-01-01'
    AND creation_date <  '2022-01-01'
),
questions_flag AS (
  SELECT
    q.dow,
    q.day_name,
    -- does this question have at least one answer posted ≤ 1 hour later?
    EXISTS (
      SELECT 1
      FROM `bigquery-public-data.stackoverflow.posts_answers` a
      WHERE a.parent_id = q.id
        AND a.creation_date <= q.creation_date + INTERVAL 1 HOUR
    ) AS answered_within_hour
  FROM questions_2021 q
)
SELECT
  day_name,
  COUNT(*)                                               AS total_questions,
  COUNTIF(answered_within_hour)                          AS answered_within_hour,
  ROUND( SAFE_DIVIDE(COUNTIF(answered_within_hour),
                     COUNT(*)) * 100 , 2 )               AS pct_answered_within_hour
FROM questions_flag
GROUP BY dow, day_name
ORDER BY dow;