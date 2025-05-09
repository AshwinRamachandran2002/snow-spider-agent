-- longest number of days between a user’s first visit
-- and their “last recorded event”, where that event is on a mobile device.
-- “Last recorded event”  = first mobile transaction if it exists,
--                          otherwise the last mobile visit.

WITH sessions AS (
  SELECT
    fullVisitorId,
    TIMESTAMP_SECONDS(visitStartTime)                      AS visit_ts,
    IFNULL(totals.transactions,0)                         AS transactions,
    IFNULL(device.isMobile,FALSE)                         AS is_mobile
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

per_user AS (
  SELECT
    fullVisitorId,

    -- first ever visit (any device)
    MIN(visit_ts)                                                AS first_visit_ts,

    -- first transaction that happened on a mobile device
    MIN( IF(is_mobile AND transactions > 0 , visit_ts, NULL) )   AS first_tx_mobile_ts,

    -- last visit that happened on a mobile device
    MAX( IF(is_mobile , visit_ts, NULL) )                        AS last_visit_mobile_ts
  FROM sessions
  GROUP BY fullVisitorId
),

last_event AS (
  SELECT
    fullVisitorId,
    first_visit_ts,

    -- choose the “last recorded event” per the rule
    COALESCE(first_tx_mobile_ts, last_visit_mobile_ts) AS last_event_ts
  FROM per_user
  WHERE COALESCE(first_tx_mobile_ts, last_visit_mobile_ts) IS NOT NULL   -- keep users whose last event is on mobile
)

SELECT
  MAX( DATE_DIFF( DATE(last_event_ts), DATE(first_visit_ts), DAY) ) AS longest_days
FROM last_event;