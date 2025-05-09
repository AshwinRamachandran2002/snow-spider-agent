-- For every visitor who purchased in February-2017:
--   • first visit date in Feb
--   • first transaction date in Feb
--   • days elapsed between the two
--   • device category used for that first transaction
WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)              AS visit_date,
    totals.transactions                     AS transactions,
    device.deviceCategory                   AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

-- first February visit of each visitor (whether it transacted or not)
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(visit_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

-- every session in February that contained at least one transaction
tx_sessions AS (
  SELECT
    fullVisitorId,
    visit_date,
    device_category
  FROM feb_sessions
  WHERE transactions IS NOT NULL
    AND transactions > 0
),

-- pick the earliest transaction-session for each visitor
first_tx AS (
  SELECT
    fullVisitorId,
    visit_date   AS first_tx_date,
    device_category,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId ORDER BY visit_date) AS rn
  FROM tx_sessions
)

SELECT
  ft.fullVisitorId,
  DATE_DIFF(ft.first_tx_date, fv.first_visit_date, DAY) AS days_elapsed,
  ft.device_category                                    AS first_tx_device
FROM first_tx  AS ft
JOIN first_visit AS fv
  ON fv.fullVisitorId = ft.fullVisitorId
WHERE ft.rn = 1;