-- Find the user with the longest (first-to-last) month span who
--  • shows at least one empty month inside that span, and
--  • has no activity in or after September-2024.
-- Only events through 10-Sep-2024 are considered.

WITH monthly AS (   -- unique (user, month) pairs up to the cut-off date
  SELECT
    `by`                                 AS user,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `by` IS NOT NULL
    AND `timestamp` < TIMESTAMP '2024-09-11'          -- include data through 10-Sep-2024
  GROUP BY user, month
),
agg AS (            -- first/last month and count of active months per user
  SELECT
    user,
    MIN(month) AS first_month,
    MAX(month) AS last_month,
    COUNT(*)   AS active_months
  FROM monthly
  GROUP BY user
),
calc AS (           -- span length and how many months inside the span are missing
  SELECT
    user,
    DATE_DIFF(last_month, first_month, MONTH) + 1                 AS month_number,
    DATE_DIFF(last_month, first_month, MONTH) + 1 - active_months AS missing_months
  FROM agg
  WHERE DATE_DIFF(last_month, first_month, MONTH) + 1 - active_months > 0   -- ≥1 gap
    AND last_month < DATE '2024-09-01'                                      -- no activity in/after Sep-2024
)
SELECT
  user AS inactive_user,
  month_number
FROM calc
ORDER BY month_number DESC
LIMIT 1;