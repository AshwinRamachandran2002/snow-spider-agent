-- First-visit date, first-transaction date, days elapsed between them,
-- and the device category used on that first transaction
WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)          AS session_date,
    totals.transactions                 AS transactions,
    device.deviceCategory               AS device_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

-- 1) First February visit per visitor
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date_feb
  FROM feb_sessions
  GROUP BY fullVisitorId
),

-- 2) First February transaction date per visitor
first_txn_date AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_txn_date_feb
  FROM feb_sessions
  WHERE transactions > 0
  GROUP BY fullVisitorId
),

-- 3) Attach device used on that first transaction
first_txn_session AS (
  SELECT
    fs.fullVisitorId,
    fs.session_date   AS first_txn_date_feb,
    fs.device_type    AS first_txn_device
  FROM feb_sessions AS fs
  JOIN first_txn_date AS ft
    ON  ft.fullVisitorId      = fs.fullVisitorId
    AND ft.first_txn_date_feb = fs.session_date
)

-- Final result
SELECT
  fv.fullVisitorId,
  fv.first_visit_date_feb,
  fts.first_txn_date_feb,
  DATE_DIFF(fts.first_txn_date_feb, fv.first_visit_date_feb, DAY) AS days_elapsed,
  fts.first_txn_device
FROM first_txn_session AS fts
JOIN first_visit AS fv
USING (fullVisitorId)
ORDER BY days_elapsed, fullVisitorId;