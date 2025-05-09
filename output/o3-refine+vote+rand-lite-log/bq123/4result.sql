WITH questions AS (
  SELECT
    id,
    creation_date,
    FORMAT_TIMESTAMP('%A', creation_date) AS day_name          -- Monday, Tuesday, …
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`
),
first_answers AS (                                              -- earliest answer per question
  SELECT
    parent_id               AS question_id,
    MIN(creation_date)      AS first_answer_date
  FROM
    `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY
    question_id
),
question_flags AS (                                             -- flag if answered within 1 hour
  SELECT
    q.day_name,
    IF(
      fa.first_answer_date IS NOT NULL
      AND TIMESTAMP_DIFF(fa.first_answer_date, q.creation_date, SECOND) <= 3600,
      1, 0) AS within_hour
  FROM
    questions q
  LEFT JOIN
    first_answers fa
  ON
    fa.question_id = q.id
),
day_percent AS (                                                 -- percentage per day of week
  SELECT
    day_name,
    100 * SAFE_DIVIDE(SUM(within_hour), COUNT(*)) AS pct_within_hour
  FROM
    question_flags
  GROUP BY
    day_name
)
SELECT
  day_name,
  ROUND(pct_within_hour, 4) AS pct_within_hour                  -- four‑decimal precision
FROM
  day_percent
ORDER BY
  pct_within_hour DESC,        -- rank days by percentage
  day_name                     -- deterministic tie‑breaker
LIMIT 1
OFFSET 2;                      -- third highest (0‑based offset)