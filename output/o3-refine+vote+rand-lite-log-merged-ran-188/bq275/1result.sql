WITH sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    PARSE_DATE('%Y%m%d', date)           AS session_date,
    IFNULL(totals.transactions, 0)       AS transactions,
    device.deviceCategory                AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM sessions
  GROUP BY fullVisitorId
),

first_transaction AS (
  SELECT
    fullVisitorId,
    session_date      AS first_tx_date,
    device_category
  FROM (
    SELECT
      fullVisitorId,
      session_date,
      visitStartTime,
      device_category,
      ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                         ORDER BY session_date, visitStartTime) AS rn
    FROM sessions
    WHERE transactions > 0
  )
  WHERE rn = 1
    AND device_category = 'mobile'        -- first transaction occurred on a mobile device
)

SELECT DISTINCT
  fullVisitorId
FROM first_transaction
JOIN first_visit USING (fullVisitorId)
WHERE first_tx_date > first_visit_date     -- transaction happened after the first visit
ORDER BY fullVisitorId;