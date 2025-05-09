-- Identify the user whose activity-span (in months) is the longest
-- while containing at least one “gap” month and who has since become inactive.
WITH activity_months AS (          -- every (user, month) pair up to 2024-09-10
  SELECT
    `by` AS user,
    DATE_TRUNC(DATE(timestamp), MONTH) AS month_val
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `by` IS NOT NULL
    AND timestamp < '2024-09-10'
),
agg AS (                           -- per-user activity metrics
  SELECT
    user,
    COUNT(DISTINCT month_val)                                     AS active_months,
    MIN(month_val)                                                AS first_month,
    MAX(month_val)                                                AS last_month,
    DATE_DIFF(MAX(month_val), MIN(month_val), MONTH) + 1          AS month_span,
    DATE_DIFF(DATE '2024-09-10', MAX(month_val), MONTH)           AS months_since_last
  FROM activity_months
  GROUP BY user
),
candidates AS (                    -- users with a gap and now inactive
  SELECT
    user,
    month_span AS month_number     -- months counted from first activity month
  FROM agg
  WHERE active_months < month_span     -- at least one missing month inside span
    AND months_since_last > 0          -- no activity after last recorded month
)
SELECT
  user,
  month_number
FROM candidates
ORDER BY month_number DESC          -- highest span first
LIMIT 1;                             -- top user meeting the criteria