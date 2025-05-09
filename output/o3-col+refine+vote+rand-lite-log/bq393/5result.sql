/* -------------------------------------------------------------
   User with the longest activity span (measured in months from
   their first post) who nevertheless shows at least one month
   of inactivity within that span, considering data only up to
   10-Sep-2024 and ignoring dead/deleted items.
--------------------------------------------------------------*/
WITH scoped AS (            -- keep only genuine records in scope
  SELECT
    `by` AS user_id,
    DATE_TRUNC(DATE(`timestamp`), MONTH) AS activity_month
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `by` IS NOT NULL
    AND (`dead`    IS NULL OR `dead`    = FALSE)
    AND (`deleted` IS NULL OR `deleted` = FALSE)
    AND `timestamp` < '2024-09-11'       -- up to 10-Sep-2024 (UTC)
),
indexed AS (                -- month_index = 1,2,3,… from first month
  SELECT
    user_id,
    DATE_DIFF(
      activity_month,
      MIN(activity_month) OVER (PARTITION BY user_id),
      MONTH
    ) + 1 AS month_index            -- months since first activity
  FROM scoped
),
per_user AS (               -- summarise per user
  SELECT
    user_id,
    COUNT(DISTINCT month_index) AS active_months,
    MAX(month_index)            AS span_months   -- overall length
  FROM indexed
  GROUP BY user_id
  HAVING active_months < span_months             -- must have a gap
),
ranked AS (                 -- pick the longest such span
  SELECT
    user_id,
    span_months,
    ROW_NUMBER() OVER (ORDER BY span_months DESC) AS rn
  FROM per_user
)
SELECT
  user_id,
  span_months AS month_number_from_first_activity
FROM ranked
WHERE rn = 1;