WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    DATE(PARSE_DATE('%Y%m%d', `date`))                       AS session_date,
    IFNULL(totals.transactions, 0)                           AS transactions,
    device.deviceCategory                                    AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

first_visit AS (   -- first February‑2017 session for each visitor
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

first_transaction AS (  -- earliest February‑2017 transaction session for each visitor
  SELECT
    fullVisitorId,
    session_date,
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
  fv.fullVisitorId,
  DATE_DIFF(ft.session_date, fv.first_visit_date, DAY) AS days_elapsed,
  ft.device_category
FROM first_visit fv
JOIN first_transaction ft USING (fullVisitorId)
ORDER BY fullVisitorId;