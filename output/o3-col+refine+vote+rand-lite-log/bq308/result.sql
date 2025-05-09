WITH questions_2021 AS (
  SELECT
    id AS question_id,
    creation_date
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),
first_answers AS (
  SELECT
    q.question_id,
    q.creation_date                       AS q_time,
    MIN(a.creation_date)                  AS first_answer_time
  FROM questions_2021 AS q
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
         ON a.parent_id = q.question_id
  GROUP BY q.question_id, q_time
),
stats AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM q_time)                               AS dow_num,      -- 1 = Sunday … 7 = Saturday
    FORMAT_DATE('%A', DATE(q_time))                              AS week_day,
    COUNT(*)                                                     AS total_questions,
    COUNTIF(first_answer_time IS NOT NULL
            AND TIMESTAMP_DIFF(first_answer_time, q_time, MINUTE) <= 60)
                                                                AS answered_within_1h
  FROM first_answers
  GROUP BY dow_num, week_day
)
SELECT
  week_day,
  total_questions,
  answered_within_1h,
  ROUND(100 * answered_within_1h / total_questions, 2)           AS pct_answered_within_1h
FROM stats
ORDER BY dow_num;