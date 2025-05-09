/*  Questions asked in 2021 by weekday,
    along with how many (and what %) received an answer within 60 minutes */
WITH per_question AS (
  SELECT
    q.id                                   AS question_id,
    q.creation_date                        AS question_time,
    -- earliest answer (if any) for this question
    (
      SELECT MIN(a.creation_date)
      FROM   `bigquery-public-data.stackoverflow.posts_answers` AS a
      WHERE  a.parent_id = q.id
    )                                      AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE EXTRACT(YEAR FROM q.creation_date) = 2021
)

SELECT
  FORMAT_DATE('%A', DATE(question_time))                                   AS weekday_name,
  COUNT(*)                                                                 AS total_questions,
  COUNTIF(first_answer_time IS NOT NULL
          AND TIMESTAMP_DIFF(first_answer_time, question_time, MINUTE) <= 60)
                                                                            AS answered_within_hour,
  ROUND(100 * COUNTIF(first_answer_time IS NOT NULL
                      AND TIMESTAMP_DIFF(first_answer_time, question_time, MINUTE) <= 60)
          / COUNT(*), 2)                                                    AS pct_answered_within_hour
FROM per_question
GROUP BY weekday_name
ORDER BY total_questions DESC;