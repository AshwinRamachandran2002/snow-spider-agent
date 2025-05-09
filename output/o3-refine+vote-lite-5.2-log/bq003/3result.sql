-- Average pageviews per visitor for purchase vs. non‑purchase sessions  
-- (Apr 1 – Jul 31 2017)

WITH sessions AS (
  SELECT
    PARSE_DATE('%Y%m%d', `date`)                                    AS session_date,
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', `date`))              AS month,
    fullVisitorId,
    COALESCE(totals.pageviews, 0)                                   AS pageviews,
    totals.transactions                                             AS transactions,
    -- does the session contain at least one productRevenue value?
    EXISTS (
      SELECT 1
      FROM UNNEST(hits) AS h
      CROSS JOIN UNNEST(h.product) AS p
      WHERE p.productRevenue IS NOT NULL
      LIMIT 1
    )                                                              AS has_product_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE _TABLE_SUFFIX BETWEEN '0401' AND '0731'           -- 20170401 – 20170731
),

classified AS (
  SELECT
    month,
    fullVisitorId,
    pageviews,
    CASE
      WHEN transactions >= 1 AND has_product_revenue            THEN 'purchase'
      WHEN transactions IS NULL AND NOT has_product_revenue     THEN 'non_purchase'
    END                                                         AS session_type
  FROM sessions
  -- keep only sessions that clearly fall into one of the two groups
  WHERE (transactions >= 1  AND has_product_revenue)
     OR (transactions IS NULL AND NOT has_product_revenue)
),

visitor_monthly AS (
  -- total pageviews a visitor generated in each month / group
  SELECT
    month,
    session_type,
    fullVisitorId,
    SUM(pageviews) AS pageviews_per_visitor
  FROM classified
  GROUP BY month, session_type, fullVisitorId
)

SELECT
  month,
  session_type,
  ROUND(AVG(pageviews_per_visitor), 4) AS avg_pageviews_per_visitor
FROM visitor_monthly
GROUP BY month, session_type
ORDER BY month, session_type;