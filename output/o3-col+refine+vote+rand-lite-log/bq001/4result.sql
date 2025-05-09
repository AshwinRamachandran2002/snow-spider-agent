/*  For every visitor who generated ≥1 transaction during February-2017:
    – date of the first session in February
    – date & device of the first February transaction
    – days elapsed between those two dates                                         */

WITH feb_sessions AS (            -- all sessions in Feb-2017
  SELECT
    fullVisitorId,
    date,
    visitStartTime,
    totals.transactions                           AS transactions,   -- leaf field
    device.deviceCategory                         AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

first_visits AS (                 -- first Feb session per visitor
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', date)) AS first_feb_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

first_txn AS (                    -- earliest Feb transaction per visitor
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)     AS first_txn_date,
    device_category                AS first_txn_device,
    ROW_NUMBER() OVER (
      PARTITION BY fullVisitorId
      ORDER BY PARSE_DATE('%Y%m%d', date), visitStartTime
    ) AS rn
  FROM feb_sessions
  WHERE transactions IS NOT NULL                    -- sessions with ≥1 transaction
)

SELECT
  fv.fullVisitorId                                       AS visitor_id,
  fv.first_feb_visit_date                                AS first_visit_date,
  ft.first_txn_date                                      AS first_transaction_date,
  DATE_DIFF(ft.first_txn_date, fv.first_feb_visit_date, DAY)
      AS days_between_first_visit_and_first_txn,
  ft.first_txn_device                                    AS device_of_first_txn
FROM first_visits fv
JOIN first_txn  ft ON fv.fullVisitorId = ft.fullVisitorId
WHERE ft.rn = 1                                          -- keep earliest transaction
ORDER BY visitor_id;