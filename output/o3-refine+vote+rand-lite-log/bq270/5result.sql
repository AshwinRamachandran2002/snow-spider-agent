-- monthly add‑to‑cart and purchase conversion rates
-- (as % of product–detail pageviews) for Jan–Mar 2017
WITH monthly_totals AS (
  SELECT
    DATE_TRUNC(PARSE_DATE('%Y%m%d', date), MONTH)          AS month_start,
    
    /* product–detail pageviews (action_type = 2, not an impression) */
    SUM(
      CASE
        WHEN hit.eCommerceAction.action_type = '2'
             AND (prd.isImpression IS NULL OR prd.isImpression = FALSE)
        THEN 1 ELSE 0
      END
    ) AS detail_views,
    
    /* add‑to‑cart events (action_type = 3) */
    SUM(
      CASE
        WHEN hit.eCommerceAction.action_type = '3'
             AND (prd.isImpression IS NULL OR prd.isImpression = FALSE)
        THEN 1 ELSE 0
      END
    ) AS add_to_cart,
    
    /* completed‑purchase events (action_type = 6) */
    SUM(
      CASE
        WHEN hit.eCommerceAction.action_type = '6'
             AND (prd.isImpression IS NULL OR prd.isImpression = FALSE)
        THEN 1 ELSE 0
      END
    ) AS purchases
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits)   AS hit
  LEFT JOIN
    UNNEST(hit.product) AS prd
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  GROUP BY
    month_start
)

SELECT
  FORMAT_DATE('%Y-%m', month_start)                                   AS month,
  ROUND(add_to_cart  * 100.0 / detail_views, 4) AS add_to_cart_rate_pct,
  ROUND(purchases    * 100.0 / detail_views, 4) AS purchase_rate_pct
FROM
  monthly_totals
ORDER BY
  month_start;