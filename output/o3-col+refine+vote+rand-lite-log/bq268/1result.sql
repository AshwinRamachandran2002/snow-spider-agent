-- Longest span (in days) between a user’s first-ever visit and their
-- last recorded mobile event (first transaction if any, otherwise last visit)

WITH sessions AS (          -- flatten all daily tables
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)          AS visit_date,
    visitStartTime                      AS visit_ts,
    device.isMobile                     AS is_mobile,
    totals.transactions                 AS txns
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

first_visit AS (            -- first visit per user
  SELECT
    fullVisitorId,
    MIN(visit_date) AS first_visit_date
  FROM sessions
  GROUP BY fullVisitorId
),

last_visit AS (             -- last session per user + its device flag
  SELECT
    fullVisitorId,
    MAX(visit_date) AS last_visit_date,
    ARRAY_AGG(is_mobile ORDER BY visit_date DESC, visit_ts DESC LIMIT 1)[OFFSET(0)]
      AS last_visit_mobile
  FROM sessions
  GROUP BY fullVisitorId
),

first_txn AS (              -- first transaction (if any) per user
  SELECT
    fullVisitorId,
    MIN(visit_date) AS first_txn_date
  FROM sessions
  WHERE txns IS NOT NULL
  GROUP BY fullVisitorId
),

last_event AS (             -- choose first txn date if exists, else last visit date
  SELECT
    lv.fullVisitorId,
    COALESCE(ft.first_txn_date, lv.last_visit_date) AS last_event_date
  FROM last_visit lv
  LEFT JOIN first_txn ft
    ON lv.fullVisitorId = ft.fullVisitorId
  WHERE lv.last_visit_mobile = TRUE               -- keep users whose last event was mobile
),

gaps AS (                   -- days between first visit and last (mobile) event
  SELECT
    fv.fullVisitorId,
    DATE_DIFF(le.last_event_date, fv.first_visit_date, DAY) AS day_gap
  FROM first_visit fv
  JOIN last_event le
    ON fv.fullVisitorId = le.fullVisitorId
)

SELECT
  MAX(day_gap) AS max_days_between_first_and_last_mobile_event
FROM gaps;