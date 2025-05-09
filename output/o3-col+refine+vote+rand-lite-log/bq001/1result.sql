-- Days between a visitor’s first February-2017 visit and their first February-2017
-- transaction, plus the device category used for that first transaction
WITH feb_sessions AS (   -- every session in Feb-2017, minimal fields
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)              AS session_date,
    visitStartTime,
    totals.transactions                     AS transactions,
    device.deviceCategory                   AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

visitors_with_txn AS (   -- all visitors who transacted at least once in February
  SELECT DISTINCT fullVisitorId
  FROM feb_sessions
  WHERE transactions IS NOT NULL
),

first_visit AS (        -- first February visit for those visitors
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  WHERE fullVisitorId IN (SELECT fullVisitorId FROM visitors_with_txn)
  GROUP BY fullVisitorId
),

first_txn AS (          -- first February transaction session for each visitor
  SELECT
    fullVisitorId,
    session_date  AS first_txn_date,
    device_category
  FROM (
    SELECT
      fullVisitorId,
      session_date,
      visitStartTime,
      device_category,
      ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                         ORDER BY session_date, visitStartTime) AS rn
    FROM feb_sessions
    WHERE transactions IS NOT NULL
  )
  WHERE rn = 1
)

SELECT
  ft.fullVisitorId,
  DATE_DIFF(ft.first_txn_date, fv.first_visit_date, DAY)
      AS days_between_first_visit_and_first_txn,
  ft.device_category AS device_used_for_first_txn
FROM first_txn  ft
JOIN first_visit fv USING (fullVisitorId)
ORDER BY ft.fullVisitorId;