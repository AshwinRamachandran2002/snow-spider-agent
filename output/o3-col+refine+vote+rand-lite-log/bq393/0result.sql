WITH monthly AS (
  -- All activity up to 10-Sep-2024, rounded to the month
  SELECT
    `by` AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS activity_month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `by` IS NOT NULL
    AND `timestamp` < '2024-09-11'          -- keep data until 10-Sep-2024
),
per_user AS (
  -- First/last month, total span length, and how many months actually seen
  SELECT
    user_id,
    MIN(activity_month) AS first_month,
    MAX(activity_month) AS last_month,
    COUNT(DISTINCT activity_month) AS actual_months,
    DATE_DIFF(MAX(activity_month), MIN(activity_month), MONTH) + 1 AS month_number
  FROM monthly
  GROUP BY user_id
),
eligible AS (
  -- Users who missed at least one month inside their span
  -- and have been inactive since before Sep-2024
  SELECT *
  FROM per_user
  WHERE (month_number - actual_months) > 0      -- at least one missing month
    AND last_month < DATE('2024-09-01')         -- no activity after their last month
)
-- User with the highest span index
SELECT
  user_id,
  month_number
FROM eligible
ORDER BY month_number DESC
LIMIT 1;