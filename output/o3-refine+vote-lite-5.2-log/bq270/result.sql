/* Monthly add‑to‑cart and purchase conversion rates
   (page‑view level) – Jan, Feb, Mar 2017 */
WITH hits_flat AS (
  -- One row per hit for the first three months of 2017
  SELECT
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)                 AS hit_date,
    SAFE_CAST(hit.eCommerceAction.action_type AS INT64) AS action_type,   -- 2 = detail, 3 = add‑to‑cart, 6 = purchase
    NOT EXISTS (                                        -- TRUE when the hit has no product impressions
      SELECT 1
      FROM UNNEST(hit.product) p
      WHERE p.isImpression = TRUE
    )                                                   AS no_impression
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hit
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
),

monthly_counts AS (
  SELECT
    FORMAT_DATE('%Y-%m', hit_date)                               AS month,
    COUNTIF(action_type = 2 AND no_impression)                   AS detail_views,
    COUNTIF(action_type = 3)                                     AS add_to_carts,
    COUNTIF(action_type = 6)                                     AS purchases
  FROM hits_flat
  GROUP BY month
)

SELECT
  month,
  ROUND(add_to_carts * 100.0 / detail_views, 4)  AS add_to_cart_rate_pct,
  ROUND(purchases   * 100.0 / detail_views, 4)   AS purchase_rate_pct
FROM monthly_counts
ORDER BY month;