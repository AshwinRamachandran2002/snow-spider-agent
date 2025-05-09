WITH product_detail_views AS (
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', t.date)) AS month,
    COUNT(*) AS product_detail_views
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
    UNNEST(t.hits) AS h,
    UNNEST(h.product) AS p
  WHERE
    h.eCommerceAction.action_type = '2'
    AND _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND (p.isImpression IS NULL OR p.isImpression = FALSE)
  GROUP BY
    month
),
add_to_cart_actions AS (
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', t.date)) AS month,
    COUNT(*) AS add_to_cart_actions
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
    UNNEST(t.hits) AS h,
    UNNEST(h.product) AS p
  WHERE
    h.eCommerceAction.action_type = '3'
    AND _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND (p.isImpression IS NULL OR p.isImpression = FALSE)
  GROUP BY
    month
),
purchase_actions AS (
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', t.date)) AS month,
    COUNT(*) AS purchase_actions
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
    UNNEST(t.hits) AS h,
    UNNEST(h.product) AS p
  WHERE
    h.eCommerceAction.action_type = '6'
    AND _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND (p.isImpression IS NULL OR p.isImpression = FALSE)
  GROUP BY
    month
)
SELECT
  CASE p.month
    WHEN 1 THEN 'Jan-2017'
    WHEN 2 THEN 'Feb-2017'
    WHEN 3 THEN 'Mar-2017'
  END AS Month,
  ROUND(SAFE_MULTIPLY(SAFE_DIVIDE(a.add_to_cart_actions, p.product_detail_views), 100), 4) AS Add_to_Cart_Conversion_Rate,
  ROUND(SAFE_MULTIPLY(SAFE_DIVIDE(pur.purchase_actions, p.product_detail_views), 100), 4) AS Purchase_Conversion_Rate
FROM
  product_detail_views p
  LEFT JOIN add_to_cart_actions a ON p.month = a.month
  LEFT JOIN purchase_actions pur ON p.month = pur.month
ORDER BY
  p.month;