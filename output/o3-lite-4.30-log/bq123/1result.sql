WITH per_question AS (
  SELECT
    q.id,
    EXTRACT(DAYOFWEEK FROM q.creation_date) AS dow,
    q.creation_date,
    MIN(a.creation_date) AS first_answer_date
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers`  AS a
    ON a.parent_id = q.id
  GROUP BY q.id, dow, q.creation_date
),
answered_within_hour AS (
  SELECT
    dow,
    COUNTIF(TIMESTAMP_DIFF(first_answer_date, creation_date, MINUTE) <= 60) AS answered_cnt
  FROM per_question
  GROUP BY dow
),
total_questions AS (
  SELECT
    EXTRACT(DAYOFWEEK FROM creation_date) AS dow,
    COUNT(*) AS total_cnt
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  GROUP BY dow
),
stats AS (
  SELECT
    t.dow,
    CASE t.dow
      WHEN 1 THEN 'Sunday'
      WHEN 2 THEN 'Monday'
      WHEN 3 THEN 'Tuesday'
      WHEN 4 THEN 'Wednesday'
      WHEN 5 THEN 'Thursday'
      WHEN 6 THEN 'Friday'
      WHEN 7 THEN 'Saturday'
    END AS day_of_week,
    SAFE_DIVIDE(a.answered_cnt, t.total_cnt) AS percentage
  FROM total_questions AS t
  JOIN answered_within_hour AS a USING (dow)
),
ranked AS (
  SELECT
    day_of_week,
    percentage,
    DENSE_RANK() OVER (ORDER BY percentage DESC) AS rnk
  FROM stats
)
SELECT
  day_of_week,
  ROUND(percentage, 4) AS percentage
FROM ranked
WHERE rnk = 3;