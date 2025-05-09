WITH sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    device.isMobile             AS is_mobile,
    totals.transactions         AS txn_cnt
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- 1) first and last time we ever saw each visitor
base AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_ts,
    MAX(visitStartTime) AS last_visit_ts
  FROM sessions
  GROUP BY fullVisitorId
),

-- 2) first session that contained a transaction for each visitor
first_txn AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_txn_ts
  FROM sessions
  WHERE txn_cnt IS NOT NULL
  GROUP BY fullVisitorId
),

-- 3) decide what the “last recorded event” is
events AS (
  SELECT
    b.fullVisitorId,
    b.first_visit_ts,
    COALESCE(f.first_txn_ts, b.last_visit_ts) AS last_event_ts
  FROM base b
  LEFT JOIN first_txn f USING (fullVisitorId)
),

-- 4) retain only visitors whose last‐event session was on a mobile device
mobile_last_events AS (
  SELECT DISTINCT
    e.fullVisitorId,
    e.first_visit_ts,
    e.last_event_ts
  FROM events e
  JOIN sessions s
    ON  s.fullVisitorId  = e.fullVisitorId
    AND s.visitStartTime = e.last_event_ts
  WHERE s.is_mobile = TRUE
)

-- 5) compute the span (in days) and keep the maximum
SELECT
  fullVisitorId,
  DATE_DIFF(
      DATE(TIMESTAMP_SECONDS(last_event_ts)),
      DATE(TIMESTAMP_SECONDS(first_visit_ts)),
      DAY
  ) AS days_between
FROM mobile_last_events
ORDER BY days_between DESC
LIMIT 1;