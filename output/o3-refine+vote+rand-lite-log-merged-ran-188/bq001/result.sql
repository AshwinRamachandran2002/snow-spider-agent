-- For every visitor with ≥1 transaction in Feb-2017, show:
--   • days between first Feb visit and first Feb transaction
--   • device category used during that first transaction
WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    date,
    visitStartTime,
    totals.transactions,
    device.deviceCategory AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

first_visit AS (
  SELECT
    fullVisitorId,
    MIN(date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

first_transaction AS (
  SELECT
    fullVisitorId,
    MIN(date) AS first_trans_date,
    -- capture the device used in the very first Feb transaction
    ARRAY_AGG(device_category ORDER BY date, visitStartTime LIMIT 1)[OFFSET(0)]
        AS first_trans_device
  FROM feb_sessions
  WHERE transactions IS NOT NULL
  GROUP BY fullVisitorId
)

SELECT
  ft.fullVisitorId,
  DATE_DIFF(PARSE_DATE('%Y%m%d', ft.first_trans_date),
            PARSE_DATE('%Y%m%d', fv.first_visit_date),
            DAY)          AS days_elapsed,
  ft.first_trans_device AS device_category
FROM first_transaction ft
JOIN first_visit      fv
ON   fv.fullVisitorId = ft.fullVisitorId
ORDER BY fullVisitorId;