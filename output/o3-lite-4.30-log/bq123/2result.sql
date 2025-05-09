WITH per_question AS (
  SELECT
    q.id,
    q.creation_date AS question_time,
    MIN(a.creation_date) AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.parent_id = q.id
  GROUP BY q.id, q.creation_date
),
per_day AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM question_time) AS dow,
    COUNT(*) AS total_questions,
    SUM(CASE WHEN TIMESTAMP_DIFF(first_answer_time, question_time, MINUTE) <= 60 THEN 1 ELSE 0 END) AS answered_within_hour
  FROM per_question
  GROUP BY dow
),
ranked_days AS (
  SELECT
    FORMAT_DATE('%A', DATE '1970-01-04' + dow - 1) AS day_of_week,
    100 * answered_within_hour / total_questions AS percentage,
    DENSE_RANK() OVER (ORDER BY 100 * answered_within_hour / total_questions DESC) AS pct_rank
  FROM per_day
)
SELECT
  day_of_week,
  ROUND(percentage, 4) AS percentage
FROM ranked_days
WHERE pct_rank = 3;