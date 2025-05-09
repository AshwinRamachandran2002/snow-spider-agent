WITH sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    totals.transactions AS transactions,
    device.isMobile AS is_mobile
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_ts
  FROM sessions
  GROUP BY fullVisitorId
),
first_tx AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_tx_ts
  FROM sessions
  WHERE transactions > 0
  GROUP BY fullVisitorId
),
last_visit AS (
  SELECT
    fullVisitorId,
    MAX(visitStartTime) AS last_visit_ts
  FROM sessions
  GROUP BY fullVisitorId
),
last_event AS (
  SELECT
    fv.fullVisitorId,
    fv.first_visit_ts,
    COALESCE(ft.first_tx_ts, lv.last_visit_ts) AS last_event_ts
  FROM first_visit fv
  LEFT JOIN first_tx ft USING (fullVisitorId)
  LEFT JOIN last_visit lv USING (fullVisitorId)
),
mobile_last_event AS (
  SELECT
    le.fullVisitorId,
    le.first_visit_ts,
    le.last_event_ts
  FROM last_event le
  JOIN sessions s
    ON  s.fullVisitorId  = le.fullVisitorId
    AND s.visitStartTime = le.last_event_ts
  WHERE s.is_mobile = TRUE
),
gaps AS (
  SELECT
    fullVisitorId AS user_id,
    DATE_DIFF(
      DATE(TIMESTAMP_SECONDS(last_event_ts)),
      DATE(TIMESTAMP_SECONDS(first_visit_ts)),
      DAY
    ) AS days_between_first_visit_and_last_mobile_event
  FROM mobile_last_event
)
SELECT
  user_id,
  days_between_first_visit_and_last_mobile_event
FROM gaps
ORDER BY days_between_first_visit_and_last_mobile_event DESC, user_id
LIMIT 1;