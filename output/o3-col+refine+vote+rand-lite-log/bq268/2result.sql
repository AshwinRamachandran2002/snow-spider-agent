/* longest gap (days) between first visit and last-recorded event
   where that last event occurred during a mobile session            */

WITH visits AS (        -- every session
  SELECT
    fullVisitorId,
    visitStartTime,               -- epoch-seconds
    device.isMobile AS is_mobile
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

first_tx AS (           -- first transaction moment per shopper
  SELECT
    fullVisitorId,
    MIN(visitStartTime + CAST(hit.time / 1000 AS INT64)) AS first_tx_ts
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits) AS hit
  WHERE hit.transaction.transactionId IS NOT NULL
  GROUP BY fullVisitorId
),

first_last AS (         -- first & last session per user (+ first-tx time)
  SELECT
    v.fullVisitorId,
    MIN(v.visitStartTime) AS first_visit_ts,
    MAX(v.visitStartTime) AS last_visit_ts,
    ft.first_tx_ts
  FROM visits AS v
  LEFT JOIN first_tx AS ft USING (fullVisitorId)
  GROUP BY v.fullVisitorId, ft.first_tx_ts
),

last_event AS (         -- when was the very last recorded event
  SELECT
    fullVisitorId,
    first_visit_ts,
    GREATEST(last_visit_ts, COALESCE(first_tx_ts, 0)) AS last_event_ts
  FROM first_last
),

mobile_last_event AS (  -- keep only users whose *last* event was on mobile
  SELECT le.*
  FROM last_event AS le
  JOIN visits     AS v
    ON  v.fullVisitorId  = le.fullVisitorId
    AND v.visitStartTime = le.last_event_ts   -- session of the last event
  WHERE v.is_mobile = TRUE
)

SELECT
  MAX(
    DATE_DIFF(
      DATE(TIMESTAMP_SECONDS(last_event_ts)),
      DATE(TIMESTAMP_SECONDS(first_visit_ts)),
      DAY
    )
  ) AS max_days_between
FROM mobile_last_event;