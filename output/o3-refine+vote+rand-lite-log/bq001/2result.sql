-- Visitors’ first‑visit vs. first‑transaction gap in February 2017
WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)                        AS session_date,
    visitStartTime,
    totals.transactions                               AS transactions,
    device.deviceCategory                             AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

-- First visit in Feb and first transaction in Feb for every visitor
first_dates AS (
  SELECT
    fullVisitorId,
    MIN(session_date)                                           AS first_visit_date,
    MIN(IF(transactions > 0, session_date, NULL))               AS first_txn_date
  FROM feb_sessions
  GROUP BY fullVisitorId
  HAVING first_txn_date IS NOT NULL          -- keep only visitors with a transaction
),

-- Device used in the first transaction session
first_txn_device AS (
  SELECT
    fs.fullVisitorId,
    ARRAY_AGG(fs.device_category
              ORDER BY fs.session_date, fs.visitStartTime)[OFFSET(0)] AS first_txn_device
  FROM feb_sessions AS fs
  JOIN first_dates  AS fd
    ON fs.fullVisitorId = fd.fullVisitorId
   AND fs.transactions  > 0
   AND fs.session_date  = fd.first_txn_date        -- sessions that are the first transaction day
  GROUP BY fs.fullVisitorId
)

SELECT
  fd.fullVisitorId,
  DATE_DIFF(fd.first_txn_date, fd.first_visit_date, DAY) AS days_elapsed,
  d.first_txn_device                                     AS device_category
FROM first_dates       AS fd
JOIN first_txn_device  AS d  USING (fullVisitorId)
ORDER BY days_elapsed DESC, fullVisitorId;