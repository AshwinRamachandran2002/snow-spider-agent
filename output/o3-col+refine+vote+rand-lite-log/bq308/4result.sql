WITH questions_2021 AS (
  SELECT
    id,
    creation_date,
    EXTRACT(DAYOFWEEK FROM creation_date) AS dow   -- 1 = Sun … 7 = Sat
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),
answers_1h AS (
  -- questions that received at least one answer within 60 minutes
  SELECT DISTINCT
    q.id,
    q.dow
  FROM questions_2021 AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.parent_id = q.id
   AND TIMESTAMP_DIFF(a.creation_date, q.creation_date, MINUTE) <= 60
)
SELECT
  q.dow,
  COUNT(*)                         AS questions_asked,
  COUNT(ans.id)                    AS answered_within_hour,
  ROUND(100 * COUNT(ans.id) / COUNT(*), 2) AS pct_answered_within_hour
FROM questions_2021 AS q
LEFT JOIN answers_1h AS ans
USING (id, dow)
GROUP BY q.dow
ORDER BY q.dow;