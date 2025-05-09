-- Average pageviews per visitor (purchase vs non-purchase) by month
WITH session AS (
  SELECT
    _TABLE_SUFFIX                                         AS table_date,
    fullVisitorId,
    totals.pageviews                                      AS session_pageviews,
    totals.transactions                                   AS session_transactions,
    ( SELECT SUM(p.productRevenue)
      FROM UNNEST(hits) AS h, UNNEST(h.product) AS p )    AS session_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),

visitor_month AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', table_date))      AS month,
    fullVisitorId,
    SUM(session_pageviews)                              AS visitor_pageviews,
    SUM(IFNULL(session_transactions,0))                 AS visitor_transactions,
    SUM(IFNULL(session_revenue,0))                      AS visitor_revenue
  FROM session
  GROUP BY month, fullVisitorId
),

flagged AS (
  SELECT
    month,
    fullVisitorId,
    visitor_pageviews,
    CASE
      WHEN visitor_transactions >= 1 AND visitor_revenue > 0
           THEN 'purchase'
      ELSE 'non_purchase'
    END AS visitor_type
  FROM visitor_month
)

SELECT
  month,
  visitor_type,
  ROUND(AVG(visitor_pageviews),4) AS avg_pageviews_per_visitor
FROM flagged
GROUP BY month, visitor_type
ORDER BY month, visitor_type;