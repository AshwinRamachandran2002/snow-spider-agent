WITH sessions AS (
  SELECT
    fullVisitorId,
    date,                                            -- YYYYMMDD
    SAFE_CAST(totals.transactions AS INT64) AS txn,  -- number of transactions in the session
    device.deviceCategory                            -- desktop / mobile / tablet …
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- first ever session for every user
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(date) AS first_visit_date
  FROM sessions
  GROUP BY fullVisitorId
),

-- first session that contained at least one transaction (any device)
first_tx AS (
  SELECT
    fullVisitorId,
    MIN(date) AS first_tx_date
  FROM sessions
  WHERE txn > 0
  GROUP BY fullVisitorId
),

-- first session with a transaction that was made on a *mobile* device
first_mobile_tx AS (
  SELECT
    fullVisitorId,
    MIN(date) AS first_mobile_tx_date
  FROM sessions
  WHERE txn > 0
    AND LOWER(deviceCategory) = 'mobile'
  GROUP BY fullVisitorId
)

SELECT DISTINCT
  fv.fullVisitorId
FROM first_visit          fv
JOIN first_tx             ft   USING (fullVisitorId)
JOIN first_mobile_tx      fmt  USING (fullVisitorId)
-- ensure the very first transaction happened on mobile …
WHERE fmt.first_mobile_tx_date = ft.first_tx_date
-- … and it occurred after the very first visit
  AND fmt.first_mobile_tx_date > fv.first_visit_date;