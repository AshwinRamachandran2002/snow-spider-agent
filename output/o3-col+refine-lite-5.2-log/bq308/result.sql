WITH per_question AS (
  -- every 2021 question with the timestamp of its first answer (if any)
  SELECT
    q.id                                   AS question_id,
    EXTRACT(DAYOFWEEK FROM q.creation_date) AS dow,           -- 1=Sun … 7=Sat
    q.creation_date                        AS question_time,
    MIN(a.creation_date)                   AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
         ON a.parent_id = q.id
  WHERE EXTRACT(YEAR FROM q.creation_date) = 2021
  GROUP BY question_id, dow, question_time
)

SELECT
  dow,
  COUNT(*) AS total_questions,
  COUNTIF(first_answer_time IS NOT NULL
          AND TIMESTAMP_DIFF(first_answer_time, question_time, SECOND) <= 3600)
        AS answered_within_1h,
  ROUND(
    100 * COUNTIF(first_answer_time IS NOT NULL
                  AND TIMESTAMP_DIFF(first_answer_time, question_time, SECOND) <= 3600)
      / COUNT(*),
    2
  ) AS pct_within_1h
FROM per_question
GROUP BY dow
ORDER BY dow;