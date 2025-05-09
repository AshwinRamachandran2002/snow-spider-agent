-- visitor IDs whose first ever transaction happened later than their first visit
-- and that first transaction was made on a device classified as 'mobile'
WITH all_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)           AS session_date,
    visitStartTime,
    IFNULL(totals.transactions, 0)       AS transactions,
    device.deviceCategory                AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

first_visit AS (               -- earliest session per visitor
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM all_sessions
  GROUP BY fullVisitorId
),

first_transaction AS (         -- earliest transaction‑bearing session per visitor
  SELECT
    fullVisitorId,
    ARRAY_AGG(
      STRUCT(session_date, visitStartTime, device_category)
      ORDER BY session_date, visitStartTime
      LIMIT 1
    )[OFFSET(0)] AS first_txn
  FROM all_sessions
  WHERE transactions > 0
  GROUP BY fullVisitorId
)

SELECT DISTINCT
  ft.fullVisitorId
FROM first_transaction  ft
JOIN first_visit        fv USING (fullVisitorId)
WHERE ft.first_txn.session_date > fv.first_visit_date      -- transaction after first visit
  AND ft.first_txn.device_category = 'mobile';             -- made on a mobile device