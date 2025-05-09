WITH all_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date) AS date,
    TIMESTAMP_SECONDS(visitStartTime) AS visitStartTime,
    totals.transactions AS transactions,
    device.deviceCategory AS deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170201' AND '20170228'
),
first_visits AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_time
  FROM all_sessions
  GROUP BY fullVisitorId
),
transactions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    deviceCategory
  FROM all_sessions
  WHERE transactions >= 1
),
first_transactions AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_transaction_time
  FROM transactions
  GROUP BY fullVisitorId
),
device_categories AS (
  SELECT
    t.fullVisitorId,
    t.deviceCategory
  FROM transactions t
  JOIN first_transactions ft
    ON t.fullVisitorId = ft.fullVisitorId AND t.visitStartTime = ft.first_transaction_time
)
SELECT
  ft.fullVisitorId,
  DATE_DIFF(DATE(ft.first_transaction_time), DATE(fv.first_visit_time), DAY) AS days_elapsed,
  dc.deviceCategory AS device_category
FROM
  first_transactions ft
JOIN
  first_visits fv
ON
  ft.fullVisitorId = fv.fullVisitorId
JOIN
  device_categories dc
ON
  ft.fullVisitorId = dc.fullVisitorId
ORDER BY
  ft.fullVisitorId