-- Visitor IDs whose very first transaction happened on a **mobile** device
-- and occurred after (not on) the date of their very first visit
WITH first_visits AS (
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', date)) AS first_visit_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),
all_txns AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)         AS txn_date,
    device.deviceCategory              AS device_cat,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                       ORDER BY PARSE_DATE('%Y%m%d', date)) AS rn
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE totals.transactions IS NOT NULL
    AND totals.transactions > 0
),
first_txn AS (
  SELECT
    fullVisitorId,
    txn_date,
    device_cat
  FROM all_txns
  WHERE rn = 1
)
SELECT DISTINCT
  fv.fullVisitorId
FROM first_visits AS fv
JOIN first_txn    AS ft
ON  fv.fullVisitorId = ft.fullVisitorId
WHERE ft.device_cat = 'mobile'
  AND ft.txn_date   > fv.first_visit_date;