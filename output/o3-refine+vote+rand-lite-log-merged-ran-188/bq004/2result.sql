/*  Non‑YouTube product with the highest quantity purchased by
    visitors who bought at least one YouTube‑related product
    during July 2017                                              */
WITH purchases AS (      -- all products bought in July 2017
  SELECT
    fullVisitorId,
    pr.v2ProductName                          AS product_name,
    SAFE_CAST(pr.productQuantity AS INT64)    AS qty
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
       UNNEST(hits) AS h,
       UNNEST(h.product) AS pr
  WHERE SAFE_CAST(pr.productQuantity AS INT64) > 0               -- purchased
),
youtube_buyers AS (       -- visitors who bought any YouTube‑related product
  SELECT DISTINCT fullVisitorId
  FROM purchases
  WHERE LOWER(product_name) LIKE '%youtube%'
),
non_youtube_totals AS (   -- quantities of other products they bought
  SELECT
    p.product_name,
    SUM(p.qty) AS total_qty
  FROM purchases p
  JOIN youtube_buyers USING (fullVisitorId)
  WHERE p.product_name IS NOT NULL
    AND LOWER(p.product_name) NOT LIKE '%youtube%'
  GROUP BY p.product_name
)
SELECT product_name, total_qty
FROM non_youtube_totals
ORDER BY total_qty DESC, product_name
LIMIT 1;