/* -----------------------------------------------------------------
   Highest‑quantity “non‑YouTube” product bought in July‑2017
   by visitors who purchased at least one YouTube‑related product
------------------------------------------------------------------*/
WITH july_purchases AS (
  -- every product that was actually purchased in July‑2017
  SELECT
    fullVisitorId,
    p.v2ProductName                          AS product_name,
    LOWER(p.v2ProductName)                   AS product_name_lc,
    COALESCE(SAFE_CAST(p.productQuantity AS INT64),1) AS qty
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits)   AS h,
    UNNEST(h.product) AS p
  WHERE
        _TABLE_SUFFIX BETWEEN '01' AND '31'                 -- 2017‑07‑01 … 2017‑07‑31
    -- treat row as a purchase only if some revenue or quantity recorded
    AND (p.productRevenue IS NOT NULL
         OR p.localProductRevenue IS NOT NULL
         OR p.productQuantity IS NOT NULL)
    AND p.v2ProductName IS NOT NULL
),
youtube_buyers AS (
  -- visitors who bought at least one YouTube‑named product
  SELECT DISTINCT fullVisitorId
  FROM july_purchases
  WHERE product_name_lc LIKE '%youtube%'
),
other_product_sales AS (
  -- purchases (name NOT containing “YouTube”) by those visitors
  SELECT
    jp.product_name,
    SUM(jp.qty) AS total_qty
  FROM july_purchases jp
  JOIN youtube_buyers y
  ON  jp.fullVisitorId = y.fullVisitorId
  WHERE jp.product_name_lc NOT LIKE '%youtube%'
  GROUP BY jp.product_name
)
SELECT
  product_name,
  total_qty
FROM other_product_sales
ORDER BY total_qty DESC
LIMIT 1;