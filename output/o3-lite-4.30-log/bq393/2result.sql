WITH clean AS (
  SELECT
    `by` AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `timestamp` < '2024-09-10'
    AND `by` IS NOT NULL
    AND (deleted IS NULL OR deleted = FALSE)
    AND (dead    IS NULL OR dead    = FALSE)
    AND type IN ('story', 'comment')
),
per_user AS (
  SELECT
    user_id,
    MIN(month) AS first_month,
    MAX(month) AS last_month,
    COUNT(DISTINCT month) AS actual_months,
    DATE_DIFF(MAX(month), MIN(month), MONTH) + 1 AS span_months
  FROM clean
  GROUP BY user_id
),
with_gap AS (
  SELECT
    user_id,
    span_months AS month_number
  FROM per_user
  WHERE actual_months < span_months      -- user missed at least one month in their span
),
ranked AS (
  SELECT
    user_id,
    month_number,
    ROW_NUMBER() OVER (ORDER BY month_number DESC, user_id) AS rn
  FROM with_gap
)
SELECT
  user_id,
  month_number
FROM ranked
WHERE rn = 1;