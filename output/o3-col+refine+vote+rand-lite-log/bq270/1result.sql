WITH detail AS (
  SELECT
    CONCAT('2017-', SUBSTR(_TABLE_SUFFIX, 1, 2)) AS month,
    COUNT(*) AS detail_hits
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
       UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
    AND h.eCommerceAction.action_type = '2'               -- product-detail page-view
    -- exclude cases where every product in the hit is only an impression
    AND (SELECT COUNTIF(p.isImpression IS TRUE)
         FROM UNNEST(h.product) AS p) = 0
  GROUP BY month
),
cart AS (
  SELECT
    CONCAT('2017-', SUBSTR(_TABLE_SUFFIX, 1, 2)) AS month,
    COUNT(*) AS add_to_cart_hits
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
       UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
    AND h.eCommerceAction.action_type = '3'               -- add-to-cart
  GROUP BY month
),
purchase AS (
  SELECT
    CONCAT('2017-', SUBSTR(_TABLE_SUFFIX, 1, 2)) AS month,
    COUNT(*) AS purchase_hits
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
       UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
    AND h.eCommerceAction.action_type = '6'               -- completed purchase
  GROUP BY month
)

SELECT
  d.month,
  ROUND(SAFE_DIVIDE(c.add_to_cart_hits, d.detail_hits) * 100, 4) AS add_to_cart_rate_pct,
  ROUND(SAFE_DIVIDE(p.purchase_hits,  d.detail_hits) * 100, 4) AS purchase_rate_pct
FROM detail AS d
LEFT JOIN cart     AS c USING (month)
LEFT JOIN purchase AS p USING (month)
ORDER BY d.month;