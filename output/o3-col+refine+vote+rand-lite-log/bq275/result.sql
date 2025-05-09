-- Visitor IDs whose very first purchase happened on a **mobile** device
-- at a strictly later date than their very first recorded session
WITH first_sessions AS (
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', date)) AS first_session_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),
first_mobile_transactions AS (
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', date)) AS first_mobile_tx_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE totals.transactions > 0
    AND device.deviceCategory = 'mobile'
  GROUP BY fullVisitorId
)
SELECT DISTINCT
  fmt.fullVisitorId
FROM first_mobile_transactions AS fmt
JOIN first_sessions           AS fs
USING (fullVisitorId)
WHERE fmt.first_mobile_tx_date > fs.first_session_date;