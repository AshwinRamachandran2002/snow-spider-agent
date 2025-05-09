-- Average pageviews per visitor – purchase vs. non-purchase sessions, Apr–Jul 2017
WITH sessions AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date))          AS ym,
    fullVisitorId,
    COALESCE(totals.pageviews,0)                             AS pageviews,
    totals.transactions                                      AS transactions,
    -- aggregate product-level revenue for the session
    ( SELECT SUM(pr.productRevenue)
        FROM UNNEST(hits) h
        CROSS JOIN UNNEST(h.product) pr )                    AS product_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),
classified AS (
  SELECT
    ym,
    fullVisitorId,
    pageviews,
    CASE
      WHEN transactions >= 1 AND product_revenue IS NOT NULL                 THEN 'purchase'
      WHEN transactions IS NULL AND product_revenue IS NULL                  THEN 'non_purchase'
      ELSE 'other'
    END AS session_type
  FROM sessions
),
per_visitor AS (
  SELECT
    ym,
    session_type,
    fullVisitorId,
    SUM(pageviews)                                            AS visitor_pageviews
  FROM classified
  WHERE session_type IN ('purchase','non_purchase')
  GROUP BY ym, session_type, fullVisitorId
)
SELECT
  ym                                             AS month,
  session_type,
  ROUND(AVG(visitor_pageviews),4)                AS avg_pageviews_per_visitor
FROM   per_visitor
GROUP  BY month, session_type
ORDER  BY month, session_type;