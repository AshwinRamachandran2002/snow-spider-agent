/*  Visitor IDs whose very first transaction
    1. happened on a session whose deviceCategory = 'mobile'
    2. occurred on a later calendar date than their very first visit          */

WITH sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)              AS session_date,
    totals.transactions                     AS transactions,
    totals.transactionRevenue               AS transactionRevenue,
    totals.totalTransactionRevenue          AS totalTransactionRevenue,
    device.deviceCategory                   AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

/* first calendar date the user visited the site */
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM sessions
  GROUP BY fullVisitorId
),

/* earliest session with a transaction for every user,
   together with the device used in that session            */
first_transaction AS (
  SELECT
    s.fullVisitorId,
    ARRAY_AGG(
      STRUCT(session_date, device_category)
      ORDER BY session_date
    )[OFFSET(0)] AS first_txn          -- earliest txn session per user
  FROM sessions AS s
  WHERE (s.transactions              > 0)
        OR (s.transactionRevenue      > 0)
        OR (s.totalTransactionRevenue > 0)
  GROUP BY s.fullVisitorId
)

/* final answer */
SELECT DISTINCT
  ft.fullVisitorId
FROM first_transaction AS ft
JOIN first_visit       AS fv
  ON fv.fullVisitorId = ft.fullVisitorId
WHERE ft.first_txn.session_date  > fv.first_visit_date     -- txn later than first visit
  AND LOWER(ft.first_txn.device_category) = 'mobile';      -- device explicitly labeled mobile