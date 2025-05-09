SELECT
  FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS month,
  ROUND(
    100 * COUNTIF(h.eCommerceAction.action_type = '3')
        / COUNTIF(
            h.eCommerceAction.action_type = '2'
            AND (ARRAY_LENGTH(h.product) = 0
                 OR NOT EXISTS (SELECT 1
                                FROM UNNEST(h.product) p
                                WHERE p.isImpression = TRUE))
          )
    , 4) AS add_to_cart_conversion_pct,
  ROUND(
    100 * COUNTIF(h.eCommerceAction.action_type = '6')
        / COUNTIF(
            h.eCommerceAction.action_type = '2'
            AND (ARRAY_LENGTH(h.product) = 0
                 OR NOT EXISTS (SELECT 1
                                FROM UNNEST(h.product) p
                                WHERE p.isImpression = TRUE))
          )
    , 4) AS purchase_conversion_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
     UNNEST(hits) AS h
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
GROUP BY month
ORDER BY month;