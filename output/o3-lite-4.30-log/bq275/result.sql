WITH sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)          AS session_date,
    IFNULL(totals.transactions, 0)      AS transactions,
    device.deviceCategory               AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM sessions
  GROUP BY fullVisitorId
),

first_txn_any AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_txn_any_date
  FROM sessions
  WHERE transactions > 0
  GROUP BY fullVisitorId
),

first_txn_mobile AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_txn_mobile_date
  FROM sessions
  WHERE transactions > 0
    AND device_category = 'mobile'
  GROUP BY fullVisitorId
)

SELECT
  first_txn_mobile.fullVisitorId AS visitor_id
FROM first_txn_mobile
JOIN first_txn_any   USING (fullVisitorId)
JOIN first_visit     USING (fullVisitorId)
WHERE first_txn_mobile_date = first_txn_any_date      -- ensure the very first transaction is on mobile
  AND first_txn_mobile_date > first_visit_date        -- and it happens after the first visit
ORDER BY visitor_id;