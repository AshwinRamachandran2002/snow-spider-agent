-- Longest gap (in days) between a visitor’s very first session and
-- their last mobile-device event  (first mobile transaction OR last mobile visit)

WITH first_visit AS (
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', date)) AS first_visit_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),
first_mobile_txn AS (
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', date)) AS first_mobile_txn_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE device.isMobile = TRUE
    AND totals.transactions > 0
  GROUP BY fullVisitorId
),
last_mobile_visit AS (
  SELECT
    fullVisitorId,
    MAX(PARSE_DATE('%Y%m%d', date)) AS last_mobile_visit_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE device.isMobile = TRUE
  GROUP BY fullVisitorId
),
per_user AS (
  SELECT
    fv.fullVisitorId,
    fv.first_visit_date,
    COALESCE(tx.first_mobile_txn_date, lv.last_mobile_visit_date) AS last_event_date
  FROM first_visit       fv
  LEFT JOIN first_mobile_txn  tx USING (fullVisitorId)
  LEFT JOIN last_mobile_visit lv USING (fullVisitorId)
  WHERE COALESCE(tx.first_mobile_txn_date, lv.last_mobile_visit_date) IS NOT NULL
),
diff AS (
  SELECT
    fullVisitorId,
    DATE_DIFF(last_event_date, first_visit_date, DAY) AS days_between
  FROM per_user
)

SELECT
  MAX(days_between) AS longest_span_days
FROM diff;