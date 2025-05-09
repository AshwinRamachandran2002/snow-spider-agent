-- Average pageviews per visitor for purchase vs. non‑purchase sessions
-- between 1‑Apr‑2017 and 31‑Jul‑2017

WITH session_level AS (
  SELECT
    fullVisitorId,
    visitId,
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date))     AS month,
    IFNULL(totals.pageviews, 0)                          AS pageviews,
    totals.transactions                                  AS transactions,
    -- does the session contain at least one product with revenue?
    EXISTS (
      SELECT 1
      FROM   UNNEST(hits)   AS h
      CROSS  JOIN UNNEST(h.product) AS p
      WHERE  p.productRevenue IS NOT NULL
    )                                                   AS has_product_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),

classified_sessions AS (
  SELECT
    fullVisitorId,
    month,
    CASE
      WHEN transactions >= 1 AND has_product_revenue              THEN 'purchase'
      WHEN transactions IS NULL AND NOT has_product_revenue       THEN 'non_purchase'
    END                                                          AS session_group,
    pageviews
  FROM session_level
  WHERE (transactions >= 1 AND has_product_revenue)
        OR (transactions IS NULL AND NOT has_product_revenue)
),

visitor_month_totals AS (
  SELECT
    month,
    session_group,
    fullVisitorId,
    SUM(pageviews) AS visitor_pageviews   -- total pageviews per visitor per month per group
  FROM classified_sessions
  GROUP BY month, session_group, fullVisitorId
)

SELECT
  month,
  session_group          AS purchase_flag,
  AVG(visitor_pageviews) AS avg_pageviews_per_visitor
FROM visitor_month_totals
GROUP BY month, purchase_flag
ORDER BY month, purchase_flag;