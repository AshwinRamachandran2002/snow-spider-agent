/*  Average page‑views per visitor, by month (Apr‑Jul 2017)  
    comparing purchase vs. non‑purchase sessions          */
WITH sessions AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date))           AS month,
    fullVisitorId,
    COALESCE(totals.pageviews, 0)                              AS pageviews,
    totals.transactions                                        AS transactions,
    -- does this session contain at least one productRevenue value?
    EXISTS (
      SELECT 1
      FROM UNNEST(hits) AS h
      CROSS JOIN UNNEST(h.product) AS p
      WHERE p.productRevenue IS NOT NULL
    )                                                         AS has_product_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE date BETWEEN '20170401' AND '20170731'
),

classified AS (
  SELECT
    month,
    fullVisitorId,
    pageviews,
    CASE
      WHEN transactions >= 1 AND has_product_revenue THEN 'purchase'
      WHEN transactions IS NULL AND NOT has_product_revenue THEN 'non_purchase'
      ELSE NULL
    END AS session_type
  FROM sessions
),

visitor_level AS (
  /* roll up to visitor‑month level so each visitor contributes once
     per month & session‑type */
  SELECT
    month,
    fullVisitorId,
    session_type,
    SUM(pageviews) AS visitor_pageviews
  FROM classified
  WHERE session_type IS NOT NULL          -- keep only the two required classes
  GROUP BY month, fullVisitorId, session_type
)

SELECT
  month,
  session_type,
  ROUND(AVG(visitor_pageviews), 4) AS avg_pageviews_per_visitor
FROM visitor_level
GROUP BY month, session_type
ORDER BY month, session_type;