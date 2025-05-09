-- Which non-“YouTube” product had the highest quantity bought
-- by visitors who purchased at least one “YouTube” item in July-2017
WITH youtube_buyers AS (
  SELECT DISTINCT s.fullVisitorId
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s,
        UNNEST(s.hits)    AS h,
        UNNEST(h.product) AS p
  WHERE p.productQuantity IS NOT NULL
        AND LOWER(p.v2ProductName) LIKE '%youtube%'     -- YouTube-related item
        AND h.eCommerceAction.action_type = '6'         -- completed purchase
),
other_product_qty AS (
  SELECT
        p.v2ProductName                     AS product_name,
        SUM(p.productQuantity)              AS total_quantity
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s,
        UNNEST(s.hits)    AS h,
        UNNEST(h.product) AS p
  WHERE p.productQuantity IS NOT NULL
        AND h.eCommerceAction.action_type = '6'          -- completed purchase
        AND LOWER(p.v2ProductName) NOT LIKE '%youtube%'  -- exclude YouTube items
        AND s.fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers)
  GROUP BY product_name
)
SELECT product_name, total_quantity
FROM   other_product_qty
ORDER  BY total_quantity DESC
LIMIT 1;