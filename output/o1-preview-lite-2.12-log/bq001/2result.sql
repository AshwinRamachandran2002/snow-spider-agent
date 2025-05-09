WITH
  feb_sessions AS (
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170201`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170202`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170203`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170204`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170205`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170206`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170207`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170208`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170209`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170210`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170211`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170212`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170213`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170214`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170215`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170216`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170217`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170218`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170219`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170220`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170221`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170222`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170223`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170224`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170225`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170226`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170227`
    UNION ALL
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170228`
  ),

  first_visits AS (
    SELECT
      fullVisitorId,
      MIN(PARSE_DATE('%Y%m%d', date)) AS first_visit_date
    FROM
      feb_sessions
    GROUP BY
      fullVisitorId
  ),

  first_transactions AS (
    SELECT
      fullVisitorId,
      PARSE_DATE('%Y%m%d', date) AS transaction_date,
      device.deviceCategory AS device_category,
      ROW_NUMBER() OVER (PARTITION BY fullVisitorId ORDER BY date, visitStartTime) AS rn
    FROM
      feb_sessions
    WHERE
      totals.transactions >= 1
  )

SELECT
  t.fullVisitorId,
  DATE_DIFF(t.transaction_date, v.first_visit_date, DAY) AS days_elapsed,
  t.device_category
FROM
  first_transactions t
JOIN
  first_visits v
ON
  t.fullVisitorId = v.fullVisitorId
WHERE
  t.rn = 1;