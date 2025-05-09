/*  visitor IDs whose very first ecommerce transaction
    (totals.transactions > 0) happened:
    • on a device whose deviceCategory = 'mobile'
    • on a date/time that is later than their very first session            */

SELECT
  fullVisitorId AS visitorId
FROM (
  SELECT
      fullVisitorId,
      MIN(visitStartTime)                                                      AS first_visit_ts,
      MIN(IF(SAFE_CAST(totals.transactions AS INT64) > 0 ,
              visitStartTime , NULL))                                          AS first_txn_ts,
      ARRAY_AGG(
              IF(SAFE_CAST(totals.transactions AS INT64) > 0 ,
                 device.deviceCategory , NULL)
              IGNORE NULLS
              ORDER BY visitStartTime
      )[OFFSET(0)]                                                             AS first_txn_device
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
)
WHERE first_txn_ts IS NOT NULL           -- the user eventually purchased
  AND first_txn_ts > first_visit_ts      -- purchase happened after the very first visit
  AND first_txn_device = 'mobile';       -- purchase was made on a mobile device