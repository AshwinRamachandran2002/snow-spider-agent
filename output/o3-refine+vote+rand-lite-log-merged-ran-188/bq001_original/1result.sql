/*  Days elapsed between a visitor’s first February‑2017 session
    and their first February‑2017 transaction, plus the device
    category used in that first transaction                         */
WITH feb_sessions AS (      -- all February‑2017 sessions
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)              AS session_date,
    totals.transactions                              AS transactions,
    device.deviceCategory                            AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170201' AND '20170228'
),

first_visit AS (            -- first Feb visit per visitor
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

first_transaction AS (      -- first Feb transaction per visitor
  SELECT
    fullVisitorId,
    session_date  AS first_transaction_date,
    device_category
  FROM (
    SELECT
      fullVisitorId,
      session_date,
      device_category,
      ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                         ORDER BY session_date) AS rn
    FROM feb_sessions
    WHERE transactions > 0
  )
  WHERE rn = 1
)

SELECT
  ft.fullVisitorId AS visitor_id,
  DATE_DIFF(ft.first_transaction_date, fv.first_visit_date, DAY)
      AS days_elapsed_first_visit_to_first_transaction,
  ft.device_category AS device_type_first_transaction
FROM first_transaction AS ft
JOIN first_visit      AS fv
USING (fullVisitorId)
ORDER BY visitor_id;