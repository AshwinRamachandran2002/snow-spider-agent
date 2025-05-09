/* Monthly add‑to‑cart & purchase conversion rates
   (as % of product‑detail pageviews) from Jan‑Mar 2017 */
WITH hits_flat AS (
  SELECT
    PARSE_DATE('%Y%m%d', date)                                        AS hit_date,
    SAFE_CAST(h.eCommerceAction.action_type AS INT64)                 AS action_type,
    EXISTS (
      SELECT 1
      FROM UNNEST(IFNULL(h.product, [])) AS p
      WHERE p.isImpression = TRUE
    )                                                                 AS has_impression
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
),

monthly_counts AS (
  SELECT
    FORMAT_DATE('%Y-%m', hit_date)                                    AS month,
    -- product‑detail pageviews
    SUM(CASE WHEN action_type = 2 AND has_impression = FALSE
             THEN 1 ELSE 0 END)                                      AS detail_views,
    -- add‑to‑cart events
    SUM(CASE WHEN action_type = 3 THEN 1 ELSE 0 END)                 AS add_to_cart_hits,
    -- completed purchases
    SUM(CASE WHEN action_type = 6 THEN 1 ELSE 0 END)                 AS purchase_hits
  FROM hits_flat
  GROUP BY month
)

SELECT
  month,
  ROUND(100 * SAFE_DIVIDE(add_to_cart_hits, detail_views), 4) AS add_to_cart_conversion_rate_pct,
  ROUND(100 * SAFE_DIVIDE(purchase_hits,    detail_views), 4) AS purchase_conversion_rate_pct
FROM monthly_counts
ORDER BY month;