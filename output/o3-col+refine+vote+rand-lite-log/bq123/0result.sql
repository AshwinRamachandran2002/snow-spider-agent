WITH first_answers AS (               -- earliest answer per question
  SELECT
    parent_id AS question_id,
    MIN(creation_date) AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),

joined AS (                           -- join questions with their first answer
  SELECT
    q.id                             AS question_id,
    q.creation_date                  AS question_time,
    fa.first_answer_time,
    TIMESTAMP_DIFF(fa.first_answer_time, q.creation_date, SECOND) <= 3600
        AS within_hour               -- TRUE if answered within 60 minutes
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN first_answers AS fa
  ON q.id = fa.question_id
),

weekday_stats AS (                    -- percentage per weekday
  SELECT
    FORMAT_TIMESTAMP('%A', question_time)                  AS weekday,
    COUNT(*)                                               AS total_questions,
    SUM(CASE WHEN within_hour THEN 1 END)                  AS answered_in_hour
  FROM joined
  GROUP BY weekday
),

ranked AS (                           -- rank weekdays by percentage
  SELECT
    weekday,
    SAFE_DIVIDE(answered_in_hour, total_questions) * 100  AS pct_within_hour,
    DENSE_RANK() OVER (ORDER BY SAFE_DIVIDE(answered_in_hour, total_questions) DESC) AS rk
  FROM weekday_stats
)

SELECT
  weekday,
  ROUND(pct_within_hour, 2) AS percentage_within_hour
FROM ranked
WHERE rk = 3;