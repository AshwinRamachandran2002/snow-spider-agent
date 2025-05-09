/* For every visitor who generated at least one transaction in February‑2017
   1. find the first session (of any type) they had in February
   2. find the first session in February that contained a transaction
   3. return the number of days between those two sessions and the device
      category used in the first‑transaction session                                        */

WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', `date`)                         AS session_date,
    visitStartTime,
    IFNULL(totals.transactions,0)                       AS txn_cnt,
    device.deviceCategory                                AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

-- first visit (any kind) in Feb‑2017
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

-- first transaction session in Feb‑2017
first_txn AS (
  SELECT
    fullVisitorId,
    session_date       AS first_txn_date,
    device_category,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                       ORDER BY session_date, visitStartTime) AS rn
  FROM feb_sessions
  WHERE txn_cnt > 0
)

SELECT
  t.fullVisitorId,
  DATE_DIFF(t.first_txn_date, v.first_visit_date, DAY) AS days_elapsed,
  t.device_category                                    AS first_txn_device
FROM first_txn t
JOIN first_visit v
  ON t.fullVisitorId = v.fullVisitorId
WHERE t.rn = 1               -- keep only the very first transaction session
ORDER BY fullVisitorId;