-- Find the largest gap (in days) between a user’s first visit
-- and her/his “last recorded event” (first transaction if it exists,
-- otherwise the last visit), keeping only those users whose chosen
-- last‑event session was made on a mobile device.
WITH sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,                           -- POSIX seconds
    COALESCE(totals.transactions, 0) AS transactions,
    COALESCE(device.isMobile, FALSE) AS is_mobile
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- For every user, locate first visit, last visit
-- and first‑ever transaction (if any).
user_timeline AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime)                                             AS first_visit_ts,
    MAX(visitStartTime)                                             AS last_visit_ts,
    MIN(IF(transactions > 0, visitStartTime, NULL))                 AS first_transaction_ts
  FROM sessions
  GROUP BY fullVisitorId
),

-- Decide which timestamp is the user’s “last recorded event”.
event_choice AS (
  SELECT
    fullVisitorId,
    first_visit_ts,
    IFNULL(first_transaction_ts, last_visit_ts) AS event_ts         -- priority: first transaction
  FROM user_timeline
),

-- Keep only those users whose chosen event occurred on a mobile device.
mobile_events AS (
  SELECT
    e.fullVisitorId,
    e.first_visit_ts,
    e.event_ts
  FROM event_choice   AS e
  JOIN sessions       AS s
    ON  s.fullVisitorId = e.fullVisitorId
    AND s.visitStartTime = e.event_ts      -- exact session of the chosen event
  WHERE s.is_mobile = TRUE
)

-- Calculate the gap (in days) and pick the longest one.
SELECT
  fullVisitorId,
  DATE_DIFF(
    DATE(TIMESTAMP_SECONDS(event_ts)),
    DATE(TIMESTAMP_SECONDS(first_visit_ts)),
    DAY
  ) AS days_between_first_and_last_event
FROM mobile_events
ORDER BY days_between_first_and_last_event DESC
LIMIT 1;