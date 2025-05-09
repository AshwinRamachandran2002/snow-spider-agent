-- Days between first February visit and first February transaction
-- together with the device category used for that first transaction
WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)              AS session_date,
    totals.transactions                     AS transactions,
    device.deviceCategory                   AS device_category,
    visitStartTime
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170201' AND '20170228'            -- February 2017 tables
),

-- First visit in February for every visitor
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

-- Rank all February sessions that contain ≥1 transaction
first_txn_ranked AS (
  SELECT
    fullVisitorId,
    session_date,
    device_category,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                       ORDER BY session_date, visitStartTime) AS rn
  FROM feb_sessions
  WHERE transactions IS NOT NULL AND transactions > 0
),

-- Keep only the earliest transaction session per visitor
first_txn AS (
  SELECT
    fullVisitorId,
    session_date      AS first_txn_date,
    device_category   AS txn_device
  FROM first_txn_ranked
  WHERE rn = 1
)

SELECT
  t.fullVisitorId,
  DATE_DIFF(t.first_txn_date, v.first_visit_date, DAY) AS days_elapsed,
  t.txn_device                                         AS first_txn_device_type
FROM first_txn t
JOIN first_visit v
  ON t.fullVisitorId = v.fullVisitorId
ORDER BY t.fullVisitorId;