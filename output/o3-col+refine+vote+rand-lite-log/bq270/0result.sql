WITH base AS (
  -- all product–level hits we care about (exclude impressions)
  SELECT
    SUBSTR(s.date,1,6)                              AS month,
    h.eCommerceAction.action_type                   AS action_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
  CROSS JOIN UNNEST(s.hits)    AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND (p.isImpression IS NULL OR p.isImpression = FALSE)          -- real product events
    AND h.eCommerceAction.action_type IN ('2','3','6')              -- detail, ATC, purchase
),
detail AS (  -- denominator
  SELECT month, COUNT(*) AS detail_views
  FROM base
  WHERE action_type = '2'
  GROUP BY month
),
atc AS (     -- add-to-cart numerator
  SELECT month, COUNT(*) AS adds_to_cart
  FROM base
  WHERE action_type = '3'
  GROUP BY month
),
purch AS (   -- purchase numerator
  SELECT month, COUNT(*) AS purchases
  FROM base
  WHERE action_type = '6'
  GROUP BY month
)
SELECT
  d.month,
  ROUND(100 * a.adds_to_cart / d.detail_views, 2) AS add_to_cart_rate_pct,
  ROUND(100 * p.purchases   / d.detail_views, 2) AS purchase_rate_pct
FROM detail d
JOIN atc   a USING (month)
JOIN purch p USING (month)
ORDER BY d.month;