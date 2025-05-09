WITH all_sessions AS (
  SELECT
    fullVisitorId,
    date,
    totals.transactions AS transactions,
    LOWER(device.deviceCategory) AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- date of the very first session
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(date) AS first_visit_date
  FROM all_sessions
  GROUP BY fullVisitorId
),

-- date of the very first transaction (any device)
first_txn AS (
  SELECT
    fullVisitorId,
    MIN(date) AS first_txn_date
  FROM all_sessions
  WHERE transactions > 0
  GROUP BY fullVisitorId
),

-- date of the very first *mobile* transaction
first_mobile_txn AS (
  SELECT
    fullVisitorId,
    MIN(date) AS first_mobile_txn_date
  FROM all_sessions
  WHERE transactions > 0
    AND device_category = 'mobile'
  GROUP BY fullVisitorId
)

SELECT
  ft.fullVisitorId AS visitor_id
FROM first_txn        ft
JOIN first_mobile_txn fmt ON ft.fullVisitorId = fmt.fullVisitorId
JOIN first_visit      fv  ON ft.fullVisitorId = fv.fullVisitorId
WHERE ft.first_txn_date = fmt.first_mobile_txn_date      -- first txn is on mobile
  AND fmt.first_mobile_txn_date > fv.first_visit_date    -- happens after first visit
ORDER BY visitor_id;