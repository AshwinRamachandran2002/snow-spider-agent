WITH all_sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,                       -- epoch seconds
    totals.transactions   AS transactions,
    device.deviceCategory AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- first ever session per visitor
first_visit AS (
  SELECT DISTINCT
    fullVisitorId,
    FIRST_VALUE(visitStartTime) OVER (
      PARTITION BY fullVisitorId
      ORDER BY visitStartTime
    ) AS first_visit_ts
  FROM all_sessions
),

-- first session with a transaction per visitor
first_tx AS (
  SELECT DISTINCT
    fullVisitorId,
    FIRST_VALUE(visitStartTime) OVER (
      PARTITION BY fullVisitorId
      ORDER BY visitStartTime
    ) AS first_tx_ts,
    FIRST_VALUE(device_category) OVER (
      PARTITION BY fullVisitorId
      ORDER BY visitStartTime
    ) AS first_tx_device
  FROM all_sessions
  WHERE transactions IS NOT NULL
    AND transactions > 0
)

SELECT
  fv.fullVisitorId AS visitor_id
FROM first_visit fv
JOIN first_tx ftx
  ON fv.fullVisitorId = ftx.fullVisitorId
WHERE ftx.first_tx_device = 'mobile'          -- first transaction on mobile
  AND ftx.first_tx_ts > fv.first_visit_ts     -- after the first visit
ORDER BY visitor_id;