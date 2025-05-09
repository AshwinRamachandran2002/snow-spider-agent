WITH first_answers AS (
  SELECT
    parent_id AS question_id,
    MIN(creation_date) AS first_answer_time
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),
weekday_stats AS (
  SELECT
    FORMAT_TIMESTAMP('%A', q.creation_date)                     AS weekday,
    COUNT(*)                                                    AS total_questions,
    COUNTIF(
      TIMESTAMP_DIFF(f.first_answer_time, q.creation_date, SECOND) <= 3600
    )                                                          AS answered_within_hour
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  LEFT JOIN first_answers f
    ON q.id = f.question_id
  GROUP BY weekday
),
ranked AS (
  SELECT
    weekday,
    SAFE_DIVIDE(answered_within_hour, total_questions) AS pct_within_hour,
    DENSE_RANK() OVER (ORDER BY SAFE_DIVIDE(answered_within_hour, total_questions) DESC) AS rnk
  FROM weekday_stats
)

SELECT
  weekday,
  pct_within_hour
FROM ranked
WHERE rnk = 3;