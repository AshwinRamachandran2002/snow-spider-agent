-- Questions per weekday in 2021 and how many got their first answer within 60 minutes
WITH first_answer AS (
  SELECT
    q.id                                            AS question_id,
    EXTRACT(DAYOFWEEK FROM q.creation_date)         AS dow_num,              -- 1=Sunday … 7=Saturday
    FORMAT_TIMESTAMP('%A', q.creation_date)         AS day_name,
    q.creation_date                                 AS question_time,
    MIN(a.creation_date)                            AS first_answer_time     -- NULL if no answers
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
         ON a.parent_id = q.id
  WHERE EXTRACT(YEAR FROM q.creation_date) = 2021
  GROUP BY question_id, dow_num, day_name, question_time
)

SELECT
  dow_num                    AS day_of_week_num,
  day_name,
  COUNT(*)                   AS total_questions,
  COUNTIF(
    TIMESTAMP_DIFF(first_answer_time, question_time, MINUTE) <= 60
  )                          AS answered_within_hour,
  ROUND(
    100 * COUNTIF(
      TIMESTAMP_DIFF(first_answer_time, question_time, MINUTE) <= 60
    ) / COUNT(*), 2
  )                          AS pct_within_hour
FROM first_answer
GROUP BY dow_num, day_name
ORDER BY dow_num;