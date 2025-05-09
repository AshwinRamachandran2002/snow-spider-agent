WITH sold_products AS (     -- every item that was actually sold in 2020
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("sold_at"/1000000))             AS sale_month,
        p."name"                                                        AS product_name,
        p."retail_price",
        p."cost",
        (p."retail_price" - p."cost")                                   AS profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p
          ON ii."product_id" = p."id"
    WHERE ii."sold_at" IS NOT NULL
      AND ii."sold_at" = ii."sold_at"                                   -- removes NaN values
      AND TO_TIMESTAMP(ii."sold_at"/1000000) >= '2020-01-01'
      AND TO_TIMESTAMP(ii."sold_at"/1000000) <  '2021-01-01'
),
min_profit AS (               -- minimum profit per month
    SELECT
        sale_month,
        MIN(profit) AS min_profit
    FROM sold_products
    GROUP BY sale_month
)
SELECT
    TO_CHAR(mp.sale_month, 'YYYY-MM')          AS "MONTH",
    sp.product_name                            AS "PRODUCT_NAME_WITH_LOWEST_PROFIT"
FROM min_profit          mp
JOIN sold_products       sp
  ON sp.sale_month = mp.sale_month
 AND sp.profit     = mp.min_profit             -- only the lowest‑profit products
ORDER BY mp.sale_month, sp.product_name;       -- chronological list