-- Users whose very first transaction happened
-- (1) on a mobile device AND
-- (2) strictly after their very first visit
WITH first_visit AS (
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', date)) AS first_visit_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),
first_txn AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)                AS first_txn_date,
    device.deviceCategory                     AS device_cat,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                       ORDER BY PARSE_DATE('%Y%m%d', date), visitStartTime) AS rn
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE totals.transactions IS NOT NULL              -- sessions with ≥1 transaction
)
SELECT DISTINCT
  ft.fullVisitorId AS visitor_id
FROM first_visit fv
JOIN first_txn  ft
  ON fv.fullVisitorId = ft.fullVisitorId
WHERE ft.rn = 1                        -- keep only the very first transaction
  AND ft.device_cat = 'mobile'         -- it occurred on a mobile device
  AND ft.first_txn_date > fv.first_visit_date
ORDER BY visitor_id;