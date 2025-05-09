/*  Monthly add‑to‑cart and purchase conversion rates
    (percentage of product‑detail pageviews) – Jan‑Mar 2017   */

WITH product_actions AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
    hit.eCommerceAction.action_type                  AS action_type
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits)               AS hit,
    UNNEST(hit.product)        AS prod
  WHERE
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND (prod.isImpression IS NULL OR prod.isImpression = FALSE)  -- exclude list impressions
)

SELECT
  month,
  ROUND(100 * SUM(IF(action_type = '3', 1, 0)) / SUM(IF(action_type = '2', 1, 0)), 4)
    AS add_to_cart_conversion_rate_pct,
  ROUND(100 * SUM(IF(action_type = '6', 1, 0)) / SUM(IF(action_type = '2', 1, 0)), 4)
    AS purchase_conversion_rate_pct
FROM product_actions
GROUP BY month
ORDER BY month;