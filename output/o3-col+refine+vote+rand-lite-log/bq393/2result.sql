-- Identify the user with the longest activity span (in months) who later became inactive
-- Data limited to everything strictly before 11-Sep-2024 UTC
WITH user_months AS (
  -- One row per (user, month) in which they posted
  SELECT
    `by`                                        AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH)        AS act_month
  FROM
    `bigquery-public-data.hacker_news.full`
  WHERE
    `by` IS NOT NULL
    AND `timestamp` < '2024-09-11'              -- keep data up-to 10-Sep-2024 23:59 UTC
  GROUP BY user_id, act_month
),
agg AS (
  -- Aggregate each user’s activity months
  SELECT
    user_id,
    ARRAY_AGG(act_month ORDER BY act_month)       AS months_array,
    MIN(act_month)                                AS first_mo,
    MAX(act_month)                                AS last_mo
  FROM user_months
  GROUP BY user_id
),
with_gap AS (
  -- Keep only users who have at least one missing month inside their overall span
  SELECT
    user_id,
    DATE_DIFF(last_mo, first_mo, MONTH)               AS month_number_from_start,
    ARRAY_LENGTH(months_array)                        AS active_month_cnt
  FROM agg
  WHERE (DATE_DIFF(last_mo, first_mo, MONTH) + 1) > ARRAY_LENGTH(months_array)
)
-- Return the single user with the highest month number who later became inactive
SELECT
  user_id  AS most_persistent_then_inactive_user,
  month_number_from_start
FROM with_gap
ORDER BY month_number_from_start DESC
LIMIT 1;