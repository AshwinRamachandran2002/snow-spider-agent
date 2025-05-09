/*  Monthly add‑to‑cart & purchase conversion rates
    (percentage of product–detail pageviews) : Jan–Mar 2017                 */
WITH hit_actions AS (
  SELECT
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)                     AS session_date,
    h.eCommerceAction.action_type                           AS action_type,
    -- product‑detail pageview = action_type = 2 and NO product impressions
    CASE
      WHEN h.eCommerceAction.action_type = '2'
           AND (SELECT COUNTIF(p.isImpression = TRUE)
                FROM UNNEST(IFNULL(h.product, [])) p) = 0
      THEN TRUE
      ELSE FALSE
    END                                                     AS is_detail_view
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
        AND h.eCommerceAction.action_type IN ('2','3','6')     -- detail, add‑cart, purchase
)

SELECT
  FORMAT_DATE('%Y-%m', session_date)                                            AS month,
  COUNTIF(is_detail_view)                                                       AS product_detail_views,
  COUNTIF(action_type = '3')                                                    AS add_to_cart_actions,
  COUNTIF(action_type = '6')                                                    AS completed_purchases,
  ROUND(COUNTIF(action_type = '3') * 100.0 / NULLIF(COUNTIF(is_detail_view),0),4) AS add_to_cart_conversion_rate,
  ROUND(COUNTIF(action_type = '6') * 100.0 / NULLIF(COUNTIF(is_detail_view),0),4) AS purchase_conversion_rate
FROM hit_actions
GROUP BY month
ORDER BY month;