WITH user_events AS (
  -- first visit, last event (first transaction when present, else last visit)
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_ts,
    COALESCE(
      MIN(IF(totals.transactions > 0, visitStartTime, NULL)),  -- first txn
      MAX(visitStartTime)                                      -- else last visit
    ) AS last_event_ts
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),
mobile_last AS (
  -- keep only users whose last event occurred on a mobile device
  SELECT
    u.fullVisitorId,
    u.first_visit_ts,
    u.last_event_ts
  FROM user_events AS u
  JOIN `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
    ON s.fullVisitorId  = u.fullVisitorId
   AND s.visitStartTime = u.last_event_ts
  WHERE s.device.isMobile = TRUE
)
SELECT
  MAX(ROUND( (last_event_ts - first_visit_ts) / 86400 , 2)) AS max_days_between_first_and_last_event_mobile
FROM mobile_last;