-- visitorIds whose very first transaction
-- (1) happened on a device marked “mobile”
-- (2) took place strictly after their first‑ever visit
WITH all_sessions AS (
  SELECT
    fullVisitorId,                                        -- user id
    PARSE_DATE('%Y%m%d', date)      AS session_date,      -- session date as DATE
    visitStartTime,                                       -- to break ties within one day
    device.deviceCategory          AS device_category,    -- desktop / tablet / mobile
    totals.transactions            AS transactions        -- number of transactions in the session
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- first time we ever saw the user
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM all_sessions
  GROUP BY fullVisitorId
),

-- every session that contains at least one transaction
transaction_sessions AS (
  SELECT
    fullVisitorId,
    session_date,
    device_category,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                       ORDER BY session_date, visitStartTime) AS rn   -- 1 = first transaction session
  FROM all_sessions
  WHERE transactions > 0
),

-- pick only the very first transaction for each user
first_transaction AS (
  SELECT
    fullVisitorId,
    session_date      AS first_transaction_date,
    device_category
  FROM transaction_sessions
  WHERE rn = 1
)

-- final answer
SELECT DISTINCT
  ft.fullVisitorId AS visitorId
FROM first_transaction ft
JOIN first_visit      fv
  ON ft.fullVisitorId = fv.fullVisitorId
WHERE ft.device_category = 'mobile'           -- transaction done on mobile
  AND ft.first_transaction_date > fv.first_visit_date; -- later than first visit