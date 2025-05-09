/*  Monthly add‑to‑cart and purchase conversion rates
    (as % of product–detail pageviews) for Jan–Mar 2017               */
WITH product_events AS (
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT('2017', _TABLE_SUFFIX))       AS event_date,
    hit.eCommerceAction.action_type                          AS action_type
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits)   AS hit,
    UNNEST(hit.product) AS prod
  WHERE
        _TABLE_SUFFIX BETWEEN '0101' AND '0331'                     -- Jan‑Mar 2017
    AND hit.eCommerceAction.action_type IN ('2','3','6')            -- detail, add‑to‑cart, purchase
    AND (prod.isImpression IS NULL OR prod.isImpression = FALSE)    -- exclude list impressions
)

SELECT
  FORMAT_DATE('%Y-%m', event_date)                                    AS month,
  SUM(CASE WHEN action_type = '2' THEN 1 ELSE 0 END)                  AS product_detail_views,
  SUM(CASE WHEN action_type = '3' THEN 1 ELSE 0 END)                  AS add_to_cart_events,
  SUM(CASE WHEN action_type = '6' THEN 1 ELSE 0 END)                  AS purchase_events,
  ROUND( SAFE_DIVIDE( SUM(CASE WHEN action_type = '3' THEN 1 END)
                      ,SUM(CASE WHEN action_type = '2' THEN 1 END) ) * 100 , 4)
                                                                      AS add_to_cart_rate_pct,
  ROUND( SAFE_DIVIDE( SUM(CASE WHEN action_type = '6' THEN 1 END)
                      ,SUM(CASE WHEN action_type = '2' THEN 1 END) ) * 100 , 4)
                                                                      AS purchase_rate_pct
FROM product_events
GROUP BY month
ORDER BY month;