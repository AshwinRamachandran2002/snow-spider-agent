-- Days between a visitor’s first February‑2017 visit and their first February‑2017 transaction,
-- together with the device category used for that first transaction
WITH sessions_feb AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)               AS visit_date,
    totals.transactions                      AS transactions,
    device.deviceCategory                    AS device_category,
    visitStartTime
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

-- First visit in Feb and first transaction in Feb for each visitor
first_dates AS (
  SELECT
    fullVisitorId,
    MIN(visit_date)                                                       AS first_visit_date,
    MIN(IF(transactions IS NOT NULL AND transactions > 0, visit_date, NULL)) AS first_trans_date
  FROM sessions_feb
  GROUP BY fullVisitorId
),

-- Device category used in the session that contains the first transaction
first_trans_device AS (
  SELECT
    s.fullVisitorId,
    ANY_VALUE(s.device_category) AS device_category
  FROM sessions_feb s
  JOIN first_dates f
    ON  s.fullVisitorId = f.fullVisitorId
    AND s.visit_date   = f.first_trans_date
    AND s.transactions IS NOT NULL
    AND s.transactions > 0
  GROUP BY s.fullVisitorId
)

SELECT
  f.fullVisitorId,
  DATE_DIFF(f.first_trans_date, f.first_visit_date, DAY) AS days_elapsed,
  d.device_category                                      AS device_category_of_first_transaction
FROM first_dates f
JOIN first_trans_device d
  ON f.fullVisitorId = d.fullVisitorId
WHERE f.first_trans_date IS NOT NULL   -- keep only visitors with at least one transaction
ORDER BY days_elapsed, fullVisitorId;