-- User with the longest active-span (in months) who nevertheless missed at least one month
WITH activity AS (
  SELECT
    `by` AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS month_dt
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `timestamp` < '2024-09-11'       -- only consider data up to 10-Sep-2024
    AND `by` IS NOT NULL
),
per_user AS (
  SELECT
    user_id,
    MIN(month_dt)                                AS first_month,
    MAX(month_dt)                                AS last_month,
    COUNT(DISTINCT month_dt)                     AS active_months
  FROM activity
  GROUP BY user_id
),
gap_users AS (
  SELECT
    user_id,
    DATE_DIFF(last_month, first_month, MONTH) + 1 AS expected_months,
    active_months
  FROM per_user
  WHERE active_months < DATE_DIFF(last_month, first_month, MONTH) + 1   -- at least one gap
)
SELECT
  user_id,
  expected_months AS month_number               -- count from first month (inclusive)
FROM gap_users
ORDER BY expected_months DESC
LIMIT 1;