-- Day of week with the 3rd-highest share of questions whose first answer arrived within 60 minutes
WITH first_answer AS (
  SELECT
    parent_id                       AS question_id,
    MIN(creation_date)              AS first_answer_date
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),
q_with_answer AS (
  SELECT
    FORMAT_TIMESTAMP('%A', q.creation_date)                          AS day_of_week,
    q.creation_date,
    fa.first_answer_date
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  JOIN first_answer fa
  ON  q.id = fa.question_id              -- keeps only questions that got at least one answer
),
day_stats AS (
  SELECT
    day_of_week,
    COUNT(*)                                                               AS total_q,
    SUM( CASE WHEN TIMESTAMP_DIFF(first_answer_date, creation_date, MINUTE) <= 60 THEN 1 ELSE 0 END )
                                                                           AS answered_in_hour
  FROM q_with_answer
  GROUP BY day_of_week
),
ranked AS (
  SELECT
    day_of_week,
    ROUND( SAFE_DIVIDE(answered_in_hour, total_q) * 100 , 2)  AS pct_answered_in_hour,
    DENSE_RANK() OVER (ORDER BY SAFE_DIVIDE(answered_in_hour, total_q) DESC) AS rnk
  FROM day_stats
)
SELECT
  day_of_week,
  pct_answered_in_hour
FROM ranked
WHERE rnk = 3;