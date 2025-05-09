/* longest gap (days) between a user’s first visit and her last event
   (last visit OR first transaction) **when that last event happened
   on a mobile device**                                                */

WITH
-- 1) every session’s basic facts
sessions AS (
  SELECT
    fullVisitorId,
    DATE(PARSE_DATE('%Y%m%d', date)) AS session_date,
    device.isMobile                  AS is_mobile
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20160101' AND '20171231'   -- full demo range
),

-- 2) first & last visit per user
visits AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date,
    MAX(session_date) AS last_visit_date
  FROM sessions
  GROUP BY fullVisitorId
),

-- 3) first-ever transaction date per user (if any)
first_tx AS (
  SELECT
    fullVisitorId,
    MIN(DATE(PARSE_DATE('%Y%m%d', date))) AS first_trans_date
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS h
  WHERE
    h.transaction.transactionId IS NOT NULL
    AND _TABLE_SUFFIX BETWEEN '20160101' AND '20171231'
  GROUP BY fullVisitorId
),

-- 4) derive each user’s “last event” date
last_evt AS (
  SELECT
    v.fullVisitorId,
    v.first_visit_date,
    GREATEST(v.last_visit_date,
             IFNULL(t.first_trans_date, DATE '1900-01-01')) AS last_event_date
  FROM visits v
  LEFT JOIN first_tx t USING (fullVisitorId)
),

-- 5) flag whether that last event occurred on mobile
last_evt_device AS (
  SELECT
    l.fullVisitorId,
    l.first_visit_date,
    l.last_event_date,
    SUM(CASE WHEN s.is_mobile THEN 1 ELSE 0 END) > 0 AS is_mobile_last_event
  FROM last_evt l
  JOIN sessions s
    ON s.fullVisitorId = l.fullVisitorId
   AND s.session_date  = l.last_event_date
  GROUP BY
    l.fullVisitorId,
    l.first_visit_date,
    l.last_event_date
)

-- 6) final answer: maximum span in days
SELECT
  MAX(DATE_DIFF(last_event_date, first_visit_date, DAY))
    AS longest_days_between_first_visit_and_last_mobile_event
FROM
  last_evt_device
WHERE
  is_mobile_last_event;