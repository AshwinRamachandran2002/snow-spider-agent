/*  Monthly add-to-cart and purchase conversion rates
    ( % of product-detail pageviews ) – Jan‒Mar 2017  */

SELECT
  month,
  ROUND(add_to_cart * 100.0 / product_detail_views, 2)  AS add_to_cart_conversion_pct,
  ROUND(purchases  * 100.0 / product_detail_views, 2)  AS purchase_conversion_pct
FROM (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,

    /* product-detail pageviews (denominator) */
    COUNTIF(
      hits.eCommerceAction.action_type = '2'
      AND NOT EXISTS (
            SELECT 1
            FROM UNNEST(hits.product) p
            WHERE p.isImpression = TRUE
          )
    ) AS product_detail_views,

    /* add-to-cart hits */
    COUNTIF(hits.eCommerceAction.action_type = '3') AS add_to_cart,

    /* completed-purchase hits */
    COUNTIF(hits.eCommerceAction.action_type = '6') AS purchases

  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS hits
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  GROUP BY month
)
ORDER BY month;