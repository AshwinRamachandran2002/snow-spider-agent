-- Days elapsed between first visit (in Feb‑2017) and first transaction,
-- plus the device used for that first purchase
WITH tx_sessions AS (
  SELECT
    fullVisitorId,
    date,
    device.deviceCategory               AS tx_device,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                       ORDER BY date, visitStartTime) AS rn
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
  WHERE totals.transactions IS NOT NULL              -- sessions with a purchase
),
first_tx AS (                                         -- 1st purchase per visitor
  SELECT
    fullVisitorId,
    date        AS first_tx_date,
    tx_device
  FROM tx_sessions
  WHERE rn = 1
),
first_visit AS (                                      -- 1st Feb‑2017 visit per visitor
  SELECT
    fullVisitorId,
    MIN(date) AS first_visit_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
  GROUP BY fullVisitorId
)
SELECT
  fv.fullVisitorId                                            AS visitor_id,
  DATE(PARSE_DATE('%Y%m%d', fv.first_visit_date))             AS first_visit_date,
  DATE(PARSE_DATE('%Y%m%d', ft.first_tx_date))                AS first_tx_date,
  DATE_DIFF(DATE(PARSE_DATE('%Y%m%d', ft.first_tx_date)),
            DATE(PARSE_DATE('%Y%m%d', fv.first_visit_date)), DAY) AS days_between,
  ft.tx_device                                                AS device_of_first_tx
FROM first_visit fv
JOIN first_tx   ft USING (fullVisitorId)
ORDER BY days_between, visitor_id;