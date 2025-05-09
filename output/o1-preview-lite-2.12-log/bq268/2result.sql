WITH sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    device.isMobile AS isMobile,
    totals.transactions > 0 AS hasTransaction
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),
user_times AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_time,
    MAX(visitStartTime) AS last_visit_time,
    MIN(IF(hasTransaction, visitStartTime, NULL)) AS first_transaction_time
  FROM sessions
  GROUP BY fullVisitorId
),
user_last_event AS (
  SELECT
    fullVisitorId,
    first_visit_time,
    CASE
      WHEN first_transaction_time IS NOT NULL AND first_transaction_time >= last_visit_time THEN first_transaction_time
      ELSE last_visit_time
    END AS last_event_time
  FROM user_times
),
user_last_event_with_device AS (
  SELECT
    u.fullVisitorId,
    u.first_visit_time,
    u.last_event_time,
    s.isMobile AS isMobile_last_event
  FROM user_last_event u
  JOIN sessions s
    ON u.fullVisitorId = s.fullVisitorId
    AND u.last_event_time = s.visitStartTime
)
SELECT
  fullVisitorId,
  ROUND((last_event_time - first_visit_time)/86400, 4) AS days_between
FROM user_last_event_with_device
WHERE isMobile_last_event = TRUE
ORDER BY days_between DESC
LIMIT 1;