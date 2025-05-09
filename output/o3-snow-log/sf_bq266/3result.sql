/*  lowest-profit products that recorded at least one sale in each month of 2020  */
WITH sales_2020 AS (                                  -- every inventory item sold in 2020
    SELECT
        "product_id",
        DATE_TRUNC('month', TO_TIMESTAMP("sold_at" / 1000000)) AS month_start
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"
    WHERE "sold_at" IS NOT NULL
      AND TO_TIMESTAMP("sold_at" / 1000000) >= '2020-01-01'
      AND TO_TIMESTAMP("sold_at" / 1000000) <  '2021-01-01'
),
product_profit AS (                                   -- static profit per product
    SELECT
        "id"   AS product_id,
        "name" AS product_name,
        ("retail_price" - "cost") AS profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"
),
monthly_profit AS (                                   -- unique products with profit by month
    SELECT DISTINCT
        s.month_start,
        pp.product_name,
        pp.profit
    FROM sales_2020 s
    JOIN product_profit pp
      ON pp.product_id = s."product_id"
),
min_profit AS (                                       -- lowest profit for every month
    SELECT
        month_start,
        MIN(profit) AS min_profit
    FROM monthly_profit
    GROUP BY month_start
)
SELECT
    TO_CHAR(mp.month_start, 'YYYY-MM') AS "Month",
    mp.product_name                    AS "Product Name",
    mp.profit                          AS "Profit"
FROM monthly_profit mp
JOIN min_profit mn
  ON mp.month_start = mn.month_start
 AND mp.profit      = mn.min_profit
ORDER BY mp.month_start;                              -- chronological list