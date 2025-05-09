-- longest span (in days) between a user’s first visit and
-- his / her last recorded event (first transaction OR, if
-- no transactions, the last visit) *when that last event
-- happened on a mobile device*
WITH sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,                                   -- POSIX seconds
    device.deviceCategory           AS device_cat,
    IFNULL(totals.transactions,0)   AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- per–user important timestamps
user_events AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime)                                                     AS first_visit_ts,
    MIN(IF(transactions > 0, visitStartTime, NULL))                         AS first_transaction_ts,
    MAX(visitStartTime)                                                     AS last_visit_ts
  FROM sessions
  GROUP BY fullVisitorId
),

-- decide which timestamp is the “last recorded event”
user_last_event AS (
  SELECT
    fullVisitorId,
    first_visit_ts,
    CASE
      WHEN first_transaction_ts IS NOT NULL THEN first_transaction_ts       -- first purchase
      ELSE last_visit_ts                                                    -- otherwise last visit
    END AS last_event_ts
  FROM user_events
),

-- keep only users whose last event happened on a mobile device
mobile_users AS (
  SELECT DISTINCT
    u.fullVisitorId,
    u.first_visit_ts,
    u.last_event_ts
  FROM user_last_event   AS u
  JOIN sessions          AS s
    ON  s.fullVisitorId  = u.fullVisitorId
    AND s.visitStartTime = u.last_event_ts
  WHERE s.device_cat = 'mobile'
),

-- compute the day–difference
diffs AS (
  SELECT
    fullVisitorId,
    DATE_DIFF(
      DATE(TIMESTAMP_SECONDS(last_event_ts)),
      DATE(TIMESTAMP_SECONDS(first_visit_ts)),
      DAY
    ) AS days_between
  FROM mobile_users
)

-- return the maximum span (and the user who owns it)
SELECT
  fullVisitorId,
  days_between AS longest_days_between_first_and_last_event
FROM diffs
ORDER BY days_between DESC, fullVisitorId
LIMIT 1;