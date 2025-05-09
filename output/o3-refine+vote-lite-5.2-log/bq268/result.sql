/* Longest span (in days) between a user’s first visit and
   the user’s last recorded event (first transaction if it exists,
   otherwise the most‑recent visit) – where that last event
   happened from a mobile device                                      */
WITH sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)           AS session_date,
    visitStartTime                       AS session_ts,
    IFNULL(totals.transactions,0) > 0    AS has_transaction,
    device.isMobile                      AS is_mobile
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- first ever visit per user
first_visits AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM sessions
  GROUP BY fullVisitorId
),

-- most‑recent session per user
last_sessions AS (
  SELECT
    fullVisitorId,
    ARRAY_AGG(STRUCT(session_date, is_mobile)
              ORDER BY session_date DESC, session_ts DESC
              LIMIT 1)[OFFSET(0)].session_date AS last_session_date,
    ARRAY_AGG(STRUCT(session_date, is_mobile)
              ORDER BY session_date DESC, session_ts DESC
              LIMIT 1)[OFFSET(0)].is_mobile    AS last_session_is_mobile
  FROM sessions
  GROUP BY fullVisitorId
),

-- first transaction session (if any) per user
first_transactions AS (
  SELECT
    fullVisitorId,
    ARRAY_AGG(STRUCT(session_date, is_mobile)
              ORDER BY session_date ASC, session_ts ASC
              LIMIT 1)[OFFSET(0)].session_date AS first_transaction_date,
    ARRAY_AGG(STRUCT(session_date, is_mobile)
              ORDER BY session_date ASC, session_ts ASC
              LIMIT 1)[OFFSET(0)].is_mobile    AS first_transaction_is_mobile
  FROM sessions
  WHERE has_transaction
  GROUP BY fullVisitorId
),

/* decide which date is the “last recorded event”:
   – use first transaction if it exists,
   – otherwise use the last session                                    */
user_timeline AS (
  SELECT
    fv.fullVisitorId,
    fv.first_visit_date,
    COALESCE(ft.first_transaction_date,  ls.last_session_date)      AS last_event_date,
    COALESCE(ft.first_transaction_is_mobile, ls.last_session_is_mobile)
                                                                    AS last_event_is_mobile
  FROM first_visits      fv
  JOIN last_sessions     ls ON fv.fullVisitorId = ls.fullVisitorId
  LEFT JOIN first_transactions ft ON fv.fullVisitorId = ft.fullVisitorId
)

/* longest span (in days) where the last event occurred on mobile */
SELECT
  MAX(DATE_DIFF(last_event_date, first_visit_date, DAY)) AS longest_days
FROM user_timeline
WHERE last_event_is_mobile = TRUE;