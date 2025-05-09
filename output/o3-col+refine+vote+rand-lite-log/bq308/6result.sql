-- Questions per weekday in 2021 and how many were answered within 1 hour
WITH question_first_answer AS (
  SELECT
    q.id                                          AS question_id,
    FORMAT_DATE('%A', DATE(q.creation_date))      AS weekday,
    q.creation_date                               AS question_time,
    MIN(a.creation_date)                          AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.parent_id = q.id
  WHERE EXTRACT(YEAR FROM q.creation_date) = 2021
  GROUP BY question_id, weekday, question_time
),
classified AS (
  SELECT
    weekday,
    CASE
      WHEN first_answer_time IS NOT NULL
           AND TIMESTAMP_DIFF(first_answer_time, question_time, SECOND) <= 3600
      THEN 1 ELSE 0
    END AS answered_within_hour
  FROM question_first_answer
)
SELECT
  weekday,
  COUNT(*)                                   AS total_questions,
  SUM(answered_within_hour)                  AS answered_within_hour,
  ROUND(100 * SUM(answered_within_hour) / COUNT(*), 2)
                                             AS pct_answered_within_hour
FROM classified
GROUP BY weekday
ORDER BY weekday;