/*  Lowest-profit products (retail_price – cost) that recorded at least one sale
    in every month of calendar year 2020                                           */
WITH sales_2020 AS (   -- every inventory item that actually sold in 2020
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("sold_at" / 1000000)) AS sale_month ,
        "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"
    WHERE "sold_at" IS NOT NULL
      AND TO_TIMESTAMP("sold_at" / 1000000) >= '2020-01-01'
      AND TO_TIMESTAMP("sold_at" / 1000000) <  '2021-01-01'
), product_margin AS (  -- add product data and calculate profit
    SELECT
        s.sale_month ,
        p."name"                 AS product_name ,
        (p."retail_price" - p."cost") AS profit
    FROM sales_2020  s
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"  p
          ON p."id" = s."product_id"
), monthly_min_profit AS (   -- lowest profit per month
    SELECT
        sale_month ,
        MIN(profit) AS min_profit
    FROM product_margin
    GROUP BY sale_month
)
SELECT
    TO_CHAR(mmp.sale_month , 'YYYY-MM') AS "month" ,
    pm.product_name
FROM monthly_min_profit  mmp
JOIN product_margin      pm
  ON  pm.sale_month = mmp.sale_month
 AND pm.profit      = mmp.min_profit
ORDER BY
    mmp.sale_month ,
    pm.product_name;