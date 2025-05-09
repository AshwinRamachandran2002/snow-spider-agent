-- Visitor IDs whose first transaction happened
-- after their very first visit and on a device
-- explicitly marked as mobile
WITH first_visit AS (
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', date)) AS first_visit_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),
first_txn_session AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date) AS first_txn_date,
    device.isMobile           AS is_mobile,
    ROW_NUMBER() OVER (
      PARTITION BY fullVisitorId
      ORDER BY PARSE_DATE('%Y%m%d', date)
    ) AS rn
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE totals.transactions > 0
)
SELECT DISTINCT
  fts.fullVisitorId
FROM first_txn_session AS fts
JOIN first_visit        AS fv
USING (fullVisitorId)
WHERE fts.rn = 1                     -- keep only the first transaction
  AND fts.first_txn_date > fv.first_visit_date
  AND fts.is_mobile = TRUE;