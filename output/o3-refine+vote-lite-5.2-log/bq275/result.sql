WITH sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)            AS session_date,
    device.deviceCategory                 AS device_category,
    totals.transactions                   AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),
user_dates AS (
  SELECT
    fullVisitorId,
    MIN(session_date)                                            AS first_visit_date,
    MIN(IF(transactions > 0, session_date, NULL))                AS first_trans_date
  FROM sessions
  GROUP BY fullVisitorId
)
SELECT DISTINCT
  s.fullVisitorId AS visitorId
FROM sessions AS s
JOIN user_dates AS u
  ON s.fullVisitorId = u.fullVisitorId
WHERE s.transactions    > 0                    -- transaction in this session
  AND s.session_date    = u.first_trans_date   -- user's first‑transaction session
  AND s.device_category = 'mobile'             -- happened on a mobile device
  AND u.first_trans_date > u.first_visit_date  -- first transaction after first visit