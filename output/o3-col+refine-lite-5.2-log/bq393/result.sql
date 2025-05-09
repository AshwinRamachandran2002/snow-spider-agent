-- Find the user who stayed active for the longest span of months
-- (counting from their first active month), yet has at least one
-- internal month with no activity, considering data only up to
-- 10 Sep 2024.
WITH activity_months AS (
  -- One row per user‑month with any activity
  SELECT
    `by` AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS activity_month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `by` IS NOT NULL
    AND `timestamp` < '2024-09-10'          -- ignore future data
  GROUP BY user_id, activity_month
),
user_spans AS (
  -- Span length vs. actual active months for each user
  SELECT
    user_id,
    MIN(activity_month) AS first_month,
    MAX(activity_month) AS last_month,
    TIMESTAMP_DIFF(MAX(activity_month), MIN(activity_month), MONTH) + 1
        AS span_months,
    COUNT(*) AS active_months
  FROM activity_months
  GROUP BY user_id
)
SELECT
  user_id,
  span_months AS month_number              -- months since first activity
FROM user_spans
WHERE active_months < span_months          -- missed ≥1 month inside span
ORDER BY span_months DESC, user_id         -- longest span comes first
LIMIT 1;