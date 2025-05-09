WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date) AS session_date,
    visitStartTime,
    totals.transactions        AS transactions,
    device.deviceCategory      AS device_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

first_txn AS (
  SELECT
    fullVisitorId,
    session_date      AS first_txn_date,
    device_type,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                       ORDER BY session_date, visitStartTime) AS rn
  FROM feb_sessions
  WHERE transactions > 0
)

SELECT
  ft.fullVisitorId                                        AS visitor_id,
  DATE_DIFF(ft.first_txn_date, fv.first_visit_date, DAY) AS days_to_first_transaction,
  ft.device_type                                          AS device_type
FROM first_txn AS ft
JOIN first_visit AS fv
  ON fv.fullVisitorId = ft.fullVisitorId
WHERE ft.rn = 1
ORDER BY visitor_id;