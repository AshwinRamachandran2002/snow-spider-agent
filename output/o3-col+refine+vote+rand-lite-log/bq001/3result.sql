/* Days from first Feb-2017 visit to first Feb-2017 transaction,
   and the device used for that first transaction               */

WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date) AS session_date,
    totals.transactions        AS transactions,
    device.deviceCategory      AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

-- First February visit per visitor
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

-- First February transaction per visitor
first_txn AS (
  SELECT
    fullVisitorId,
    session_date    AS first_txn_date,
    device_category AS first_txn_device
  FROM (
    SELECT
      fullVisitorId,
      session_date,
      device_category,
      ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                         ORDER BY session_date) AS rn
    FROM feb_sessions
    WHERE transactions >= 1
  )
  WHERE rn = 1
)

SELECT
  t.fullVisitorId,
  DATE_DIFF(t.first_txn_date, v.first_visit_date, DAY) AS days_to_first_txn,
  t.first_txn_device                                   AS device_category
FROM first_txn t
JOIN first_visit v
  ON t.fullVisitorId = v.fullVisitorId;