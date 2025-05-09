WITH unioned AS (
  -- June 2017
  SELECT date, fullVisitorId, totals.pageviews AS pageviews, totals.transactions AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170601`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170602`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170603`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170604`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170605`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170606`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170607`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170608`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170609`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170610`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170611`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170612`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170613`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170614`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170615`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170616`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170617`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170618`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170619`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170620`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170621`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170622`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170623`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170624`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170625`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170626`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170627`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170628`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170629`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170630`
  -- July 2017
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170701`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170702`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170703`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170704`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170705`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170706`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170707`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170708`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170709`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170710`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170711`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170712`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170713`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170714`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170715`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170716`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170717`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170718`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170719`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170720`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170721`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170722`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170723`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170724`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170725`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170726`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170727`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170728`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170729`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170730`
  UNION ALL SELECT date, fullVisitorId, totals.pageviews, totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170731`
),
sessions AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
    fullVisitorId,
    CASE WHEN transactions > 0 THEN 'purchase' ELSE 'non_purchase' END AS session_type,
    pageviews
  FROM unioned
  WHERE date BETWEEN '20170601' AND '20170731'
    AND pageviews IS NOT NULL
),
per_visitor AS (
  SELECT
    month,
    fullVisitorId,
    session_type,
    SUM(pageviews) AS pageviews_per_visitor
  FROM sessions
  GROUP BY month, fullVisitorId, session_type
)
SELECT
  month,
  ROUND(AVG(IF(session_type = 'purchase',     pageviews_per_visitor, NULL)), 4) AS avg_pageviews_purchase,
  ROUND(AVG(IF(session_type = 'non_purchase', pageviews_per_visitor, NULL)), 4) AS avg_pageviews_non_purchase
FROM per_visitor
GROUP BY month
ORDER BY month;