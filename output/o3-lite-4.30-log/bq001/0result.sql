WITH feb_sessions AS (
  SELECT *
  FROM (
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170201` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170202` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170203` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170204` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170205` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170206` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170207` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170208` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170209` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170210` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170211` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170212` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170213` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170214` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170215` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170216` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170217` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170218` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170219` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170220` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170221` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170222` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170223` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170224` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170225` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170226` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170227` UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170228`
  )
),
feb AS (
  SELECT
    fullVisitorId,
    date,
    visitStartTime,
    totals.transactions           AS transactions,
    device.deviceCategory         AS device_type
  FROM feb_sessions
),
first_dates AS (
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', date))                                               AS first_visit_date,
    MIN(IF(transactions > 0, PARSE_DATE('%Y%m%d', date), NULL))                   AS first_txn_date
  FROM feb
  GROUP BY fullVisitorId
  HAVING first_txn_date IS NOT NULL
),
first_txn_session AS (
  SELECT
    fd.fullVisitorId,
    fd.first_txn_date,
    f.device_type,
    ROW_NUMBER() OVER (PARTITION BY fd.fullVisitorId ORDER BY f.visitStartTime)   AS rn
  FROM first_dates fd
  JOIN feb f
    ON f.fullVisitorId = fd.fullVisitorId
   AND PARSE_DATE('%Y%m%d', f.date) = fd.first_txn_date
   AND f.transactions > 0
)
SELECT
  CAST(fd.fullVisitorId AS STRING)                       AS visitor_id,
  DATE_DIFF(fd.first_txn_date, fd.first_visit_date, DAY) AS days_to_first_transaction,
  fts.device_type                                        AS device_type
FROM first_dates        AS fd
JOIN first_txn_session  AS fts
  ON fd.fullVisitorId = fts.fullVisitorId
WHERE fts.rn = 1
ORDER BY visitor_id;