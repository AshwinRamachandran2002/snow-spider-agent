/*  Days elapsed between the first February-2017 visit
    and the first February-2017 transaction for every
    visitor who bought in that month, plus the device
    category used on that first transaction.           */

WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)           AS session_date,
    totals.transactions                  AS txn_cnt,
    totals.totalTransactionRevenue       AS txn_rev,
    device.deviceCategory                AS device_cat
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

/* 1. First transaction date in February per visitor   */
first_txn AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_txn_date
  FROM feb_sessions
  WHERE txn_cnt IS NOT NULL OR txn_rev IS NOT NULL
  GROUP BY fullVisitorId
),

/* 2. First visit date in February per visitor          */
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

/* 3. Device category used on the first-transaction day */
txn_device AS (
  SELECT
    t.fullVisitorId,
    ANY_VALUE(s.device_cat) AS first_txn_device
  FROM first_txn        AS t
  JOIN feb_sessions     AS s
    ON  s.fullVisitorId = t.fullVisitorId
    AND s.session_date  = t.first_txn_date
  WHERE s.txn_cnt IS NOT NULL OR s.txn_rev IS NOT NULL
  GROUP BY t.fullVisitorId
)

SELECT
  t.fullVisitorId,
  DATE_DIFF(t.first_txn_date, v.first_visit_date, DAY) AS days_between,
  d.first_txn_device
FROM first_txn   AS t
JOIN first_visit AS v USING (fullVisitorId)
JOIN txn_device  AS d USING (fullVisitorId)
ORDER BY fullVisitorId;