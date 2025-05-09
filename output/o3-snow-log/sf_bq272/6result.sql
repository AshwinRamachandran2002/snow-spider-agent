WITH order_items_filtered AS (          -- 1. keep only successfully-sold items
    SELECT
        oi."product_id",
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) AS sales_month,
        oi."sale_price",
        ii."cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o   ON o."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii ON ii."id" = oi."inventory_item_id"
    WHERE   oi."status"      NOT IN ('Cancelled','Returned')     -- exclude cancelled / returned items
        AND o."status"       <>  'Cancelled'                     -- exclude items whose order was cancelled
        AND oi."returned_at" IS NULL                             -- exclude any that were later returned
        AND DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))
                BETWEEN DATE '2019-01-01' AND DATE '2022-08-01'  -- Jan-2019 … Aug-2022
),

profit_per_product_month AS (          -- 2. aggregate profit per product per month
    SELECT
        f.sales_month,
        p."name"                                               AS product_name,
        SUM(f."sale_price") - SUM(f."cost")                    AS profit
    FROM order_items_filtered  f
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p  ON p."id" = f."product_id"
    GROUP BY f.sales_month, p."name"
),

ranked AS (                            -- 3. rank products by profit within each month
    SELECT
        sales_month,
        product_name,
        profit,
        ROW_NUMBER() OVER (PARTITION BY sales_month
                           ORDER BY profit DESC NULLS LAST) AS rn
    FROM profit_per_product_month
)

-- 4. pick the top-3 for every month
SELECT
    TO_CHAR(sales_month, 'YYYY-MM')   AS month,
    product_name,
    ROUND(profit, 4)                  AS profit
FROM ranked
WHERE rn <= 3
ORDER BY sales_month, profit DESC NULLS LAST;