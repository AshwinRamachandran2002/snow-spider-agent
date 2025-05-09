WITH all_sessions AS (
  SELECT *
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
),

detail AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(*) AS detail_views
  FROM all_sessions
  CROSS JOIN UNNEST(hits) AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE h.eCommerceAction.action_type = '2'
    AND (p.isImpression IS NULL OR p.isImpression = FALSE)
  GROUP BY month
),

add_cart AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(*) AS add_cnt
  FROM all_sessions
  CROSS JOIN UNNEST(hits) AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE h.eCommerceAction.action_type = '3'
    AND (p.isImpression IS NULL OR p.isImpression = FALSE)
  GROUP BY month
),

purchase AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(*) AS purchase_cnt
  FROM all_sessions
  CROSS JOIN UNNEST(hits) AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE h.eCommerceAction.action_type = '6'
    AND (p.isImpression IS NULL OR p.isImpression = FALSE)
  GROUP BY month
)

SELECT
  d.month,
  ROUND(100 * COALESCE(a.add_cnt, 0)      / d.detail_views, 4) AS add_to_cart_conversion_pct,
  ROUND(100 * COALESCE(p.purchase_cnt, 0) / d.detail_views, 4) AS purchase_conversion_pct
FROM detail d
LEFT JOIN add_cart a USING (month)
LEFT JOIN purchase p USING (month)
ORDER BY d.month;