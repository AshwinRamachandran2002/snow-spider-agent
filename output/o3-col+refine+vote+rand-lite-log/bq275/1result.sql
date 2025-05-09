/*  Visitor IDs whose very first transaction happened
    (1) on a “mobile” device and
    (2) strictly after their very first visit            */
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
    PARSE_DATE('%Y%m%d', date)           AS first_txn_date,
    deviceCategory
  FROM (
    SELECT
      fullVisitorId,
      date,
      visitStartTime,
      device.deviceCategory              AS deviceCategory,
      ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                         ORDER BY date, visitStartTime) AS rn
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE totals.transactions IS NOT NULL               -- sessions with a txn
  )
  WHERE rn = 1                                          -- keep 1st-ever txn
)
SELECT DISTINCT
  t.fullVisitorId
FROM first_visit v
JOIN first_txn  t
  ON v.fullVisitorId = t.fullVisitorId
WHERE t.first_txn_date > v.first_visit_date             -- txn after 1st visit
  AND LOWER(t.deviceCategory) = 'mobile'                -- on a mobile device
ORDER BY t.fullVisitorId;