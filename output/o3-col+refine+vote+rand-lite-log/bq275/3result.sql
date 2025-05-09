/*  Visitor IDs whose very first transaction happened on a device
    labelled “mobile”, and that transaction date is AFTER their
    very first visit date                                           */

WITH first_visit AS (           -- earliest session of every user
  SELECT
    fullVisitorId,
    MIN( PARSE_DATE('%Y%m%d', date) ) AS first_visit_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),

all_txn_sessions AS (           -- every session that contains a transaction
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)              AS session_date,
    device.deviceCategory                   AS device_type,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                       ORDER BY date)       AS rn      -- 1 = first-ever txn
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE totals.transactions IS NOT NULL
    AND totals.transactions > 0
),

first_txn AS (                  -- keep only each user’s first-ever txn session
  SELECT
    fullVisitorId,
    session_date  AS first_txn_date,
    device_type   AS first_txn_device
  FROM all_txn_sessions
  WHERE rn = 1
)

SELECT
  fv.fullVisitorId
FROM first_visit  fv
JOIN first_txn    ft
USING (fullVisitorId)
WHERE ft.first_txn_device = 'mobile'        -- first txn on mobile
  AND ft.first_txn_date  > fv.first_visit_date;