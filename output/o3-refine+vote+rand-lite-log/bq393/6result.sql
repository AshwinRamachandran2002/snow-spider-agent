WITH src AS (  -- all activity up to 10‑Sep‑2024, bucketed by month
  SELECT
    `by` AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS activity_month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `timestamp` < TIMESTAMP '2024-09-11'
    AND `by` IS NOT NULL
),
user_months AS (  -- first/last month and number of distinct active months per user
  SELECT
    user_id,
    MIN(activity_month) AS first_month,
    MAX(activity_month) AS last_month,
    COUNT(DISTINCT activity_month) AS active_months_cnt
  FROM src
  GROUP BY user_id
),
user_stats AS (  -- compute span length and missing months inside that span
  SELECT
    user_id,
    first_month,
    last_month,
    DATE_DIFF(last_month, first_month, MONTH) + 1 AS span_months,
    active_months_cnt,
    (DATE_DIFF(last_month, first_month, MONTH) + 1) - active_months_cnt AS missing_months
  FROM user_months
),
qualified AS (  -- users with at least one gap and no activity after their last month
  SELECT *
  FROM user_stats
  WHERE missing_months >= 1
    AND last_month < DATE '2024-09-01'
)
SELECT
  user_id AS `by`,
  span_months AS month_number
FROM qualified
ORDER BY span_months DESC, user_id
LIMIT 1;