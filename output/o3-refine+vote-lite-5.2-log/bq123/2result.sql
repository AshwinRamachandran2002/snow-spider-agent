WITH earliest_answers AS (
  -- earliest answer time for each question
  SELECT
    parent_id AS question_id,
    MIN(creation_date) AS first_answer_date
  FROM
    `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY
    parent_id
),
day_stats AS (
  -- total questions and those answered within 1 hour for each day‑of‑week
  SELECT
    FORMAT_TIMESTAMP('%A', q.creation_date) AS day_name,
    COUNT(*) AS total_questions,
    SUM(
      CASE
        WHEN e.first_answer_date IS NOT NULL
             AND TIMESTAMP_DIFF(e.first_answer_date, q.creation_date, SECOND) <= 3600
        THEN 1 ELSE 0 END
    ) AS answered_within_hour
  FROM
    `bigquery-public-data.stackoverflow.posts_questions` AS q
  LEFT JOIN
    earliest_answers AS e
  ON
    e.question_id = q.id
  GROUP BY
    day_name
),
percentages AS (
  -- percentage answered within an hour
  SELECT
    day_name,
    answered_within_hour / total_questions * 100 AS pct
  FROM
    day_stats
),
ranked AS (
  -- rank days by percentage, highest first
  SELECT
    day_name,
    pct,
    DENSE_RANK() OVER (ORDER BY pct DESC) AS rnk
  FROM
    percentages
)
-- day with the 3rd‑highest percentage
SELECT
  day_name,
  ROUND(pct, 4) AS percentage_within_hour
FROM
  ranked
WHERE
  rnk = 3;