WITH hit_actions AS (
  -- All hits from 1 Jan 2017‑31 Mar 2017 (wild‑card over every daily table)
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date))               AS month,
    h.eCommerceAction.action_type                                  AS action_type
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  CROSS JOIN UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
)

SELECT
  month,
  detail_views            AS product_detail_pageviews,
  add_to_cart,
  purchases,
  ROUND(SAFE_DIVIDE(add_to_cart , detail_views) * 100, 4) AS add_to_cart_conversion_rate_pct,
  ROUND(SAFE_DIVIDE(purchases , detail_views)   * 100, 4) AS purchase_conversion_rate_pct
FROM (
  SELECT
    month,
    SUM(CASE WHEN action_type = '2' THEN 1 ELSE 0 END) AS detail_views,   -- product‑detail views
    SUM(CASE WHEN action_type = '3' THEN 1 ELSE 0 END) AS add_to_cart,    -- add‑to‑cart actions
    SUM(CASE WHEN action_type = '6' THEN 1 ELSE 0 END) AS purchases       -- completed purchases
  FROM hit_actions
  GROUP BY month
)
ORDER BY month;