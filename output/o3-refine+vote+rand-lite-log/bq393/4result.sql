-- User who stayed active the longest (in months counted from their first
-- active month) but then became inactive, and who also has at least one
-- “missing” month inside the span between their first and last activity.

WITH activity_per_month AS (
  SELECT
    `by`                                     AS user_id,
    DATE_TRUNC(DATE(timestamp), MONTH)       AS activity_month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE
        timestamp < '2024-09-11'          -- only data up to 2024‑09‑10
    AND `by` IS NOT NULL                    -- ignore rows without a user
),

user_month_stats AS (
  SELECT
    user_id,
    MIN(activity_month)                      AS first_month,
    MAX(activity_month)                      AS last_month,
    COUNT(DISTINCT activity_month)           AS active_month_cnt
  FROM activity_per_month
  GROUP BY user_id
),

eligible_users AS (
  SELECT
    user_id,
    -- month number of the user’s last recorded activity
    DATE_DIFF(last_month, first_month, MONTH) + 1 AS last_month_number,
    -- total months that should exist in the span
    DATE_DIFF(last_month, first_month, MONTH) + 1 AS span_month_cnt,
    active_month_cnt
  FROM user_month_stats
  -- the user must have at least one missing month inside the span
  WHERE active_month_cnt < DATE_DIFF(last_month, first_month, MONTH) + 1
),

ranked AS (
  SELECT
    user_id,
    last_month_number,
    ROW_NUMBER() OVER (ORDER BY last_month_number DESC, user_id) AS rn
  FROM eligible_users
)

SELECT
  user_id,
  last_month_number AS month_number
FROM ranked
WHERE rn = 1;