-- Average pageviews per visitor by month and session class (Jun-01-2017 – Jul-31-2017)
WITH session_level AS (
  SELECT
    fullVisitorId,
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date))            AS month,
    totals.pageviews                                            AS session_pageviews,
    IF(COALESCE(totals.transactions,0) >= 1,
       'purchase',
       'non_purchase')                                          AS session_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'     -- study window
    AND totals.pageviews IS NOT NULL                         -- keep only sessions with pageviews
),
visitor_month AS (
  -- sum pageviews per visitor, per month, per session class
  SELECT
    fullVisitorId,
    month,
    session_type,
    SUM(session_pageviews) AS visitor_month_pageviews
  FROM session_level
  GROUP BY fullVisitorId, month, session_type
)
-- final aggregation: average pageviews per visitor for each month & class
SELECT
  month,
  ROUND(AVG(IF(session_type = 'purchase',      visitor_month_pageviews, NULL)), 4)
      AS purchase_avg_pageviews,
  ROUND(AVG(IF(session_type = 'non_purchase',  visitor_month_pageviews, NULL)), 4)
      AS non_purchase_avg_pageviews
FROM visitor_month
GROUP BY month
ORDER BY month;