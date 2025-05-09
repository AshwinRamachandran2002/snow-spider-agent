WITH per_question AS (
  SELECT
    FORMAT_DATE('%A', DATE(q.creation_date)) AS weekday,
    q.creation_date                           AS question_time,
    MIN(a.creation_date)                      AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
         ON a.parent_id = q.id
  GROUP BY weekday, q.id, q.creation_date
),
per_weekday AS (
  SELECT
    weekday,
    COUNT(*) AS total_questions,
    SUM(
      CASE
        WHEN first_answer_time IS NOT NULL
             AND TIMESTAMP_DIFF(first_answer_time, question_time, MINUTE) <= 60
        THEN 1 ELSE 0
      END
    ) AS answered_in_1h
  FROM per_question
  GROUP BY weekday
),
ranked AS (
  SELECT
    weekday,
    ROUND(100 * answered_in_1h / total_questions, 4) AS pct_within_1h,
    DENSE_RANK() OVER (ORDER BY answered_in_1h / total_questions DESC) AS rnk
  FROM per_weekday
)
SELECT
  weekday         AS third_highest_weekday,
  pct_within_1h   AS percentage_within_one_hour
FROM ranked
WHERE rnk = 3;