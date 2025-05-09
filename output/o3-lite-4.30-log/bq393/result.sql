WITH base AS (
  SELECT
    `by` AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS activity_month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `timestamp` < '2024-09-11'
    AND `by` IS NOT NULL
),
user_month_index AS (
  SELECT
    user_id,
    DATE_DIFF(
      activity_month,
      MIN(activity_month) OVER (PARTITION BY user_id),
      MONTH
    ) AS month_index
  FROM base
),
per_user AS (
  SELECT
    user_id,
    ARRAY_AGG(DISTINCT month_index ORDER BY month_index) AS idxs,
    MAX(month_index)                                   AS max_idx
  FROM user_month_index
  GROUP BY user_id
),
inactive_users AS (
  SELECT
    user_id,
    max_idx
  FROM per_user
  WHERE ARRAY_LENGTH(idxs) < max_idx + 1               -- at least one missing month
)
SELECT
  user_id,
  max_idx AS month_number
FROM inactive_users
ORDER BY month_number DESC, user_id
LIMIT 1;