-- Average pageviews per visitor for purchase vs. non‑purchase sessions  
-- between 1‑Apr‑2017 and 31‑Jul‑2017
WITH sessions AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date))        AS month,   -- e.g. 2017-04
    fullVisitorId,
    COALESCE(totals.pageviews, 0)                           AS pageviews,
    totals.transactions                                     AS transactions,
    -- does this session have at least one productRevenue value?
    EXISTS (
      SELECT 1
      FROM UNNEST(hits) AS h
      CROSS JOIN UNNEST(IFNULL(h.product, [])) AS p
      WHERE p.productRevenue IS NOT NULL
    )                                                      AS has_product_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'     -- Apr 1 → Jul 31 2017
),
classified AS (
  SELECT
    month,
    fullVisitorId,
    pageviews,
    CASE
      WHEN transactions >= 1 AND has_product_revenue THEN 'purchase'
      WHEN transactions IS NULL AND NOT has_product_revenue THEN 'non_purchase'
      ELSE 'other'                                          -- ignore odd mismatches
    END AS session_type
  FROM sessions
),
visitor_month AS (
  -- aggregate pageviews at visitor‑month level inside each class
  SELECT
    month,
    session_type,
    fullVisitorId,
    SUM(pageviews) AS visitor_pageviews
  FROM classified
  WHERE session_type IN ('purchase','non_purchase')
  GROUP BY month, session_type, fullVisitorId
)
SELECT
  month,
  session_type                    AS group_type,
  AVG(visitor_pageviews)          AS avg_pageviews_per_visitor
FROM visitor_month
GROUP BY month, group_type
ORDER BY month, group_type;