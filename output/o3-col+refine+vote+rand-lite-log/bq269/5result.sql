WITH per_visitor_month AS (
  -- Sum pageviews per visitor, per month, split by purchase classification
  SELECT
    FORMAT_DATE('%Y-%m',
                PARSE_DATE('%Y%m%d', CONCAT('2017', _TABLE_SUFFIX))) AS month,
    fullVisitorId,
    -- pageviews coming from sessions that contain ≥1 transaction
    SUM(IF(totals.transactions >= 1, totals.pageviews, 0)) AS purchase_pageviews,
    -- pageviews coming from sessions that contain 0 / NULL transactions
    SUM(IF(totals.transactions IS NULL OR totals.transactions = 0,
           totals.pageviews, 0))                           AS non_purchase_pageviews
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'   -- 2017-06-01 through 2017-07-31
    AND totals.pageviews IS NOT NULL              -- keep only sessions with pageviews
  GROUP BY month, fullVisitorId
)

-- Visitor-level aggregates are now averaged to get the requested metric
SELECT
  month,
  ROUND(AVG(IF(purchase_pageviews     > 0,
               purchase_pageviews,     NULL)), 4) AS avg_pageviews_purchase,
  ROUND(AVG(IF(non_purchase_pageviews > 0,
               non_purchase_pageviews, NULL)), 4) AS avg_pageviews_non_purchase
FROM per_visitor_month
GROUP BY month
ORDER BY month;