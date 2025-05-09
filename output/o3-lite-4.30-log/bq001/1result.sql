WITH february_sessions AS (

  SELECT
    fullVisitorId,
    `date`,
    visitStartTime,
    totals.transactions AS transactions,
    device.deviceCategory AS deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170201`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170202`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170203`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170204`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170205`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170206`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170207`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170208`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170209`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170210`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170211`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170212`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170213`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170214`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170215`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170216`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170217`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170218`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170219`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170220`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170221`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170222`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170223`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170224`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170225`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170226`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170227`

  UNION ALL SELECT
    fullVisitorId, `date`, visitStartTime, totals.transactions, device.deviceCategory
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170228`
),

first_visit AS (
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', `date`)) AS first_visit_date
  FROM february_sessions
  GROUP BY fullVisitorId
),

first_transaction AS (
  SELECT
    fullVisitorId,
    `date`                             AS txn_date_str,
    deviceCategory                     AS device_type,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId ORDER BY visitStartTime) AS rn
  FROM february_sessions
  WHERE transactions IS NOT NULL AND transactions > 0
)

SELECT
  ft.fullVisitorId                   AS visitor_id,
  DATE_DIFF(PARSE_DATE('%Y%m%d', ft.txn_date_str), fv.first_visit_date, DAY)
    AS days_to_first_transaction,
  ft.device_type
FROM first_transaction ft
JOIN first_visit fv
  ON fv.fullVisitorId = ft.fullVisitorId
WHERE ft.rn = 1
ORDER BY visitor_id;