-- Elapsed days between first Feb-2017 visit and first Feb-2017 transaction,
-- together with the device category used for that first transaction
WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)            AS session_date,
    visitStartTime,
    totals.transactions                   AS transactions,
    device.deviceCategory                 AS deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

-- first visit in February per visitor
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

-- order each visitor’s transaction sessions to find the first one
ordered_txns AS (
  SELECT
    fullVisitorId,
    session_date  AS txn_date,
    deviceCategory,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                       ORDER BY session_date, visitStartTime) AS rn
  FROM feb_sessions
  WHERE transactions IS NOT NULL
),

first_txn AS (
  SELECT
    fullVisitorId,
    txn_date  AS first_txn_date,
    deviceCategory
  FROM ordered_txns
  WHERE rn = 1                      -- keep only the first transaction per visitor
)

SELECT
  t.fullVisitorId,
  DATE_DIFF(t.first_txn_date, v.first_visit_date, DAY) AS days_between_first_visit_and_txn,
  t.deviceCategory                                     AS first_txn_device
FROM first_txn t
JOIN first_visit v
  ON t.fullVisitorId = v.fullVisitorId;