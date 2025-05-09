-- User that stayed active the longest (in counted months) before going silent,
-- while having at least one internal gap in activity.
WITH activity AS (
  SELECT
    `by`                             AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS activity_month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `timestamp` < '2024-09-11'                      -- only data up to 10 Sep 2024 (inclusive)
    AND `by` IS NOT NULL                               -- keep rows with a user name
    AND (deleted IS NULL OR deleted = FALSE)            -- ignore deleted items
    AND (dead    IS NULL OR dead    = FALSE)            -- ignore dead items
),
per_user AS (                                           -- first/last month and all active months per user
  SELECT
    user_id,
    MIN(activity_month)                       AS first_month,
    MAX(activity_month)                       AS last_month,
    ARRAY_AGG(DISTINCT activity_month)        AS active_months
  FROM activity
  GROUP BY user_id
),
with_gaps AS (                                          -- count total months and internal gaps
  SELECT
    user_id,
    first_month,
    last_month,
    DATE_DIFF(last_month, first_month, MONTH) + 1       AS total_months,          -- month number of last activity
    (
      SELECT COUNT(*)                                   -- months inside span with no activity
      FROM UNNEST(GENERATE_DATE_ARRAY(first_month, last_month, INTERVAL 1 MONTH)) m
      WHERE m NOT IN UNNEST(active_months)
    ) AS missing_months_inside_span
  FROM per_user
),
inactive_users AS (                                     -- users that became inactive and had at least one gap
  SELECT *
  FROM   with_gaps
  WHERE  missing_months_inside_span > 0                 -- at least one skipped month in span
    AND  last_month < DATE '2024-09-01'                 -- no activity in or after Sep 2024
)
SELECT
  user_id,
  total_months AS month_number                          -- month count since user's first activity
FROM inactive_users
ORDER BY total_months DESC, user_id                     -- highest month number first
LIMIT 1;