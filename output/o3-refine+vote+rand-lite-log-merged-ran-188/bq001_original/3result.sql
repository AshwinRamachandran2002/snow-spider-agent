-- Days between the first February‑2017 visit and the first February‑2017 transaction,
-- plus the device category used for that first transaction
WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)      AS session_date,
    totals.transactions             AS transactions,
    device.deviceCategory           AS device_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

-- first transaction (if any) per visitor within February 2017
first_transaction AS (
  SELECT
    fullVisitorId,
    session_date  AS first_transaction_date,
    device_type   AS first_transaction_device
  FROM (
    SELECT
      fullVisitorId,
      session_date,
      device_type,
      ROW_NUMBER() OVER (PARTITION BY fullVisitorId ORDER BY session_date) AS rn
    FROM feb_sessions
    WHERE transactions > 0
  )
  WHERE rn = 1        -- keep only the earliest transaction per visitor
),

-- first February 2017 visit per visitor (transactional or not)
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
)

-- combine the two to get the elapsed days and device information
SELECT
  ft.fullVisitorId                               AS visitor_id,
  DATE_DIFF(ft.first_transaction_date,
            fv.first_visit_date,
            DAY)                                 AS days_elapsed,
  ft.first_transaction_device                    AS transaction_device_type
FROM   first_transaction AS ft
JOIN   first_visit      AS fv
       USING (fullVisitorId)
ORDER BY days_elapsed, visitor_id;