-- Monthly add‑to‑cart and purchase conversion rates
-- (as % of product‑detail pageviews) for Jan–Mar 2017
WITH
  detail AS (
    SELECT
      FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
      COUNT(1) AS detail_views
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
         UNNEST(hits) AS hit
    LEFT JOIN UNNEST(hit.product) AS prod
    WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
      AND hit.eCommerceAction.action_type = '2'           -- product‑detail view
      AND (prod.isImpression IS NULL OR prod.isImpression = FALSE)
    GROUP BY month
  ),
  cart AS (
    SELECT
      FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
      COUNT(1) AS add_to_cart_hits
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
         UNNEST(hits) AS hit
    WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
      AND hit.eCommerceAction.action_type = '3'           -- add to cart
    GROUP BY month
  ),
  purchase AS (
    SELECT
      FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
      COUNT(1) AS purchase_hits
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
         UNNEST(hits) AS hit
    WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
      AND hit.eCommerceAction.action_type = '6'           -- completed purchase
    GROUP BY month
  )
SELECT
  d.month,
  ROUND(100 * c.add_to_cart_hits / d.detail_views, 4) AS add_to_cart_rate_pct,
  ROUND(100 * p.purchase_hits   / d.detail_views, 4) AS purchase_rate_pct
FROM detail   AS d
LEFT JOIN cart     AS c USING (month)
LEFT JOIN purchase AS p USING (month)
ORDER BY d.month;