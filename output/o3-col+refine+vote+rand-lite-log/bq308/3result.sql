WITH questions_2021 AS (
  SELECT
    id,
    creation_date,
    FORMAT_DATE('%A', DATE(creation_date)) AS weekday
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE EXTRACT(YEAR FROM creation_date) = 2021
),
first_answers AS (
  SELECT
    parent_id               AS question_id,
    MIN(creation_date)      AS first_answer_time          -- first (earliest) answer per question
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),
questions_with_timing AS (
  SELECT
    q.weekday,
    q.id,
    TIMESTAMP_DIFF(fa.first_answer_time, q.creation_date, MINUTE) AS minutes_to_first_answer
  FROM questions_2021 q
  LEFT JOIN first_answers fa
         ON fa.question_id = q.id          -- NULL when the question has no answers
)
SELECT
  weekday,
  COUNT(*)                                                             AS total_questions,
  COUNTIF(minutes_to_first_answer IS NOT NULL
          AND minutes_to_first_answer <= 60)                           AS answered_within_1h,
  ROUND(
        100 * COUNTIF(minutes_to_first_answer IS NOT NULL
                      AND minutes_to_first_answer <= 60)
        / COUNT(*),                                                    2) AS pct_answered_within_1h
FROM questions_with_timing
GROUP BY weekday
ORDER BY weekday;