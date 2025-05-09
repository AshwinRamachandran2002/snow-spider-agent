/*  Visitor IDs (fullVisitorId) of users whose very first transaction
    1) happened on a device whose category is explicitly ‘mobile’
    2) and occurred on a later calendar date than their very first visit  */

WITH sessions AS (
  SELECT
    fullVisitorId,
    DATE(PARSE_DATE('%Y%m%d', `date`))                 AS session_date,
    IFNULL(totals.transactions, 0)                    AS transactions,
    device.deviceCategory                             AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- first ever session (visit) of every user
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM sessions
  GROUP BY fullVisitorId
),

-- first session that contains a transaction for every user
first_transaction AS (
  SELECT
    fullVisitorId,
    session_date       AS first_txn_date,
    device_category,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                       ORDER BY session_date) AS rn
  FROM sessions
  WHERE transactions > 0
)

SELECT DISTINCT
  ft.fullVisitorId
FROM first_transaction ft
JOIN first_visit fv
  ON ft.fullVisitorId = fv.fullVisitorId
WHERE ft.rn = 1                              -- keep only the very first transaction
  AND ft.first_txn_date > fv.first_visit_date -- must be on a later date than first visit
  AND LOWER(ft.device_category) = 'mobile';   -- transaction done on a ‘mobile’ device