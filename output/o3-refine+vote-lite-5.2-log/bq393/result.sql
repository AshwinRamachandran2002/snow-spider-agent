WITH activity_per_month AS (
  SELECT
    `by` AS user_id,
    DATE(TIMESTAMP_TRUNC(`timestamp`, MONTH)) AS activity_month
  FROM
    `bigquery-public-data.hacker_news.full`
  WHERE
    `timestamp` < TIMESTAMP('2024-09-11')  -- up to (and including) 2024‑09‑10
    AND `by` IS NOT NULL
),
distinct_user_months AS (
  SELECT DISTINCT user_id, activity_month
  FROM activity_per_month
),
user_activity_stats AS (
  SELECT
    user_id,
    MIN(activity_month) AS first_month,
    MAX(activity_month) AS last_month,
    COUNT(*) AS active_months,
    DATE_DIFF(MAX(activity_month), MIN(activity_month), MONTH) + 1 AS month_span
  FROM distinct_user_months
  GROUP BY user_id
  HAVING month_span > active_months   -- at least one missing month
),
ranked AS (
  SELECT
    user_id,
    month_span AS month_number,
    ROW_NUMBER() OVER (ORDER BY month_span DESC, user_id) AS rn
  FROM user_activity_stats
)
SELECT
  user_id,
  month_number
FROM ranked
WHERE rn = 1;