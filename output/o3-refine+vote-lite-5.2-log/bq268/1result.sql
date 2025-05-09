/* longest span (in days) from the very first visit to the last recorded
   event (last visit for non‑buyers, first purchase for buyers),
   considering only users whose last recorded event happened on a
   mobile device.                                                */
WITH sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,                      -- seconds since 1970‑01‑01
    totals.transactions                 AS transactions,
    device.isMobile                     AS is_mobile,
    device.deviceCategory               AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- per‑user milestones -------------------------------------------------
per_user AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime)                                              AS first_visit_ts,
    MIN(IF(transactions > 0, visitStartTime, NULL))                  AS first_transaction_ts,
    MAX(visitStartTime)                                              AS last_visit_ts
  FROM sessions
  GROUP BY fullVisitorId
),

-- decide which moment is the “last recorded event” -------------------
last_event AS (
  SELECT
    fullVisitorId,
    first_visit_ts,
    IF(first_transaction_ts IS NOT NULL,
       first_transaction_ts,                -- buyers → first purchase
       last_visit_ts)                       -- non‑buyers → last visit
       AS last_event_ts
  FROM per_user
),

-- bring the device information of that last event --------------------
event_device AS (
  SELECT
    l.fullVisitorId,
    l.first_visit_ts,
    l.last_event_ts,
    ANY_VALUE(s.is_mobile)        AS is_mobile,
    ANY_VALUE(s.device_category)  AS device_category
  FROM last_event l
  JOIN sessions s
    ON  s.fullVisitorId  = l.fullVisitorId
    AND s.visitStartTime = l.last_event_ts
  GROUP BY
    l.fullVisitorId, l.first_visit_ts, l.last_event_ts
),

-- keep only users whose last event was on a mobile device ------------
days_gap AS (
  SELECT
    fullVisitorId,
    DATE_DIFF( DATE(TIMESTAMP_SECONDS(last_event_ts)),
               DATE(TIMESTAMP_SECONDS(first_visit_ts)),
               DAY)                                   AS days_between
  FROM event_device
  WHERE is_mobile = TRUE OR LOWER(device_category) = 'mobile'
)

-- --------------------------------------------------------------------
SELECT
  fullVisitorId,
  days_between
FROM (
  SELECT
    fullVisitorId,
    days_between,
    ROW_NUMBER() OVER (ORDER BY days_between DESC, fullVisitorId) AS rn
  FROM days_gap
)
WHERE rn = 1;