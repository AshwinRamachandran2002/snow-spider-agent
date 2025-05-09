/* Monthly add‑to‑cart & purchase conversion rates
   (as % of product‑detail page‑views) for Jan‑Mar 2017 */

WITH monthly_counts AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', s.date))                       AS month,
    COUNTIF(h.eCommerceAction.action_type = '2')                             AS product_detail_views,
    COUNTIF(h.eCommerceAction.action_type = '3')                             AS add_to_cart_actions,
    COUNTIF(h.eCommerceAction.action_type = '6')                             AS purchase_actions
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` AS s,
    UNNEST(s.hits)                                                    AS h
  WHERE
    s.date BETWEEN '20170101' AND '20170331'     -- Jan‑Mar 2017
  GROUP BY
    month
)

SELECT
  month,
  product_detail_views,
  add_to_cart_actions,
  purchase_actions,
  ROUND(SAFE_DIVIDE(add_to_cart_actions, product_detail_views) * 100, 4) AS add_to_cart_conversion_rate_pct,
  ROUND(SAFE_DIVIDE(purchase_actions,   product_detail_views) * 100, 4) AS purchase_conversion_rate_pct
FROM
  monthly_counts
ORDER BY
  month;