WITH first_visits AS (
  -- earliest session date for every user (any device, any channel)
  SELECT
    fullVisitorId,
    MIN( PARSE_DATE('%Y%m%d', `date`) ) AS first_visit_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),
first_mobile_txns AS (
  -- earliest *mobile* session that contains a transaction
  SELECT
    fullVisitorId,
    MIN( PARSE_DATE('%Y%m%d', `date`) ) AS first_mobile_txn_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE totals.transactions > 0
    AND device.deviceCategory = 'mobile'
  GROUP BY fullVisitorId
)
SELECT DISTINCT
  v.fullVisitorId AS visitor_id
FROM first_visits        v
JOIN first_mobile_txns   t
ON  v.fullVisitorId = t.fullVisitorId
WHERE t.first_mobile_txn_date > v.first_visit_date;