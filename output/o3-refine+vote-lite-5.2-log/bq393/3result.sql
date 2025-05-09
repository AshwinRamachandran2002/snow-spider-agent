-- Find the user who stayed around for the most months (counting from their first
-- active month) but has at least one month of inactivity inside that span, and
-- who has had no further activity after their last recorded month (up to
-- 2024‑09‑10).

WITH activity_by_month AS (
  SELECT
    `by`                                AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS activity_month
  FROM
    `bigquery-public-data.hacker_news.full`
  WHERE
        `timestamp` <= '2024-09-10 00:00:00 UTC'   -- only consider data up to the cut‑off date
    AND `by` IS NOT NULL                           -- ignore missing usernames
),

user_month_stats AS (
  SELECT
    user_id,
    MIN(activity_month)                    AS first_month,
    MAX(activity_month)                    AS last_month,
    COUNT(DISTINCT activity_month)         AS active_month_cnt
  FROM activity_by_month
  GROUP BY user_id
),

users_with_gaps AS (
  SELECT
    user_id,
    DATE_DIFF(last_month, first_month, MONTH) + 1 AS total_month_number,  -- month index of last activity
    active_month_cnt
  FROM user_month_stats
  WHERE
    -- User must have at least one month between first and last where they were inactive
    DATE_DIFF(last_month, first_month, MONTH) + 1 > active_month_cnt
)

SELECT
  user_id,
  total_month_number AS month_number        -- month count since first activity
FROM users_with_gaps
ORDER BY
  total_month_number DESC,                  -- highest span first
  user_id                                   -- tie‑breaker
LIMIT 1;