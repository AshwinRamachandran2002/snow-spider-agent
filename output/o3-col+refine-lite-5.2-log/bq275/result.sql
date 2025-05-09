/*  Visitor IDs whose very first transaction
    • happened in a session whose device.category = 'mobile'
    • occurred strictly after their very first visit         */

WITH sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)            AS session_date,
    device.deviceCategory                 AS device_category,
    totals.transactions                   AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- 1. First‑ever visit date per user
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM sessions
  GROUP BY fullVisitorId
),

-- 2. All sessions that contain ≥1 transaction
txn_sessions AS (
  SELECT
    fullVisitorId,
    session_date,
    device_category
  FROM sessions
  WHERE transactions IS NOT NULL
    AND transactions > 0
),

-- 3. Earliest transaction date per user
first_txn AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_txn_date
  FROM txn_sessions
  GROUP BY fullVisitorId
),

-- 4. The session(s) that hold each user’s first transaction
first_txn_detail AS (
  SELECT
    f.fullVisitorId,
    f.first_txn_date,
    t.device_category
  FROM first_txn  f
  JOIN txn_sessions t
    ON  t.fullVisitorId = f.fullVisitorId
    AND t.session_date  = f.first_txn_date
)

-- 5. Final filter: first transaction on mobile & after first visit
SELECT DISTINCT
  ft.fullVisitorId AS visitor_id
FROM first_visit      fv
JOIN first_txn_detail ft
  ON fv.fullVisitorId = ft.fullVisitorId
WHERE ft.device_category = 'mobile'
  AND ft.first_txn_date  > fv.first_visit_date;