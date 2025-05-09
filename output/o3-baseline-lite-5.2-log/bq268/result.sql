-- longest span (in days) from a user’s very first session to the
-- “last recorded event” (first transaction if any, otherwise last visit),
-- where that last recorded event happened on a mobile device
WITH sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', `date`)                         AS session_date,
    totals.transactions                                   AS transactions,
    device.isMobile                                       AS is_mobile
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

per_user AS (
  SELECT
    fullVisitorId,

    -- first‑ever visit
    MIN(session_date) AS first_visit_date,

    -- very last visit (date + mobile flag)
    ARRAY_AGG(STRUCT(session_date, is_mobile)
              ORDER BY session_date DESC
              LIMIT 1)[OFFSET(0)]                       AS last_visit_struct,

    -- first session that contained a transaction (if any)
    ARRAY_AGG(
      IF(transactions IS NOT NULL AND transactions > 0,
         STRUCT(session_date, is_mobile),
         NULL)
      IGNORE NULLS
      ORDER BY session_date ASC
      LIMIT 1)[OFFSET(0)]                               AS first_txn_struct
  FROM sessions
  GROUP BY fullVisitorId
),

events AS (
  SELECT
    fullVisitorId,
    first_visit_date,

    -- choose the appropriate “last recorded event”
    CASE
      WHEN first_txn_struct IS NOT NULL
        THEN first_txn_struct.session_date          -- first purchase
      ELSE last_visit_struct.session_date           -- otherwise last visit
    END                                             AS last_event_date,

    CASE
      WHEN first_txn_struct IS NOT NULL
        THEN first_txn_struct.is_mobile
      ELSE last_visit_struct.is_mobile
    END                                             AS last_event_is_mobile
  FROM per_user
)

SELECT
  fullVisitorId,
  DATE_DIFF(last_event_date, first_visit_date, DAY) AS days_between
FROM events
WHERE last_event_is_mobile                       -- keep only mobile “last events”
ORDER BY days_between DESC
LIMIT 1;