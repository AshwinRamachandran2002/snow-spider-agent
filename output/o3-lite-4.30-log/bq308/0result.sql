WITH question_first_answer AS (
  SELECT
    q.id,
    q.creation_date                                             AS question_time,
    MIN(a.creation_date)                                        AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` a
         ON a.parent_id = q.id
  WHERE EXTRACT(YEAR FROM q.creation_date) = 2021
  GROUP BY q.id, q.creation_date
),
weekday_stats AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM question_time)                       AS dow_num,      -- 1‑Sunday … 7‑Saturday
    FORMAT_TIMESTAMP('%A', question_time)                       AS day_of_week,
    COUNT(*)                                                    AS total_questions,
    COUNTIF(first_answer_time IS NOT NULL
            AND TIMESTAMP_DIFF(first_answer_time, question_time, SECOND) <= 3600)
        AS answered_within_1h
  FROM question_first_answer
  GROUP BY dow_num, day_of_week
)
SELECT
  day_of_week,
  total_questions,
  answered_within_1h,
  ROUND(SAFE_DIVIDE(answered_within_1h, total_questions) * 100, 4)
      AS percent_answered_within_1h
FROM weekday_stats
ORDER BY dow_num;