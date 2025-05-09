/*  Top‑3 most profitable products per month
    (Jan‑2019 ‑ Aug‑2022, Snowflake dialect)                                      */

WITH order_items_clean AS (          -- keep only completed, non‑returned items
    SELECT
        oi."product_id",
        oi."inventory_item_id",
        oi."sale_price",
        TO_TIMESTAMP_NTZ(oi."created_at", 6) AS created_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
          ON o."order_id" = oi."order_id"
    WHERE  TO_TIMESTAMP_NTZ(oi."created_at", 6) >= '2019-01-01'::TIMESTAMP
       AND TO_TIMESTAMP_NTZ(oi."created_at", 6) <  '2022-09-01'::TIMESTAMP
       AND o."status" NOT IN ('Cancelled', 'Returned')
       AND oi."status" NOT IN ('Cancelled', 'Returned')
       AND oi."returned_at" IS NULL
),

sales_with_cost AS (                 -- aggregate sales & cost per product / month
    SELECT
        DATE_TRUNC('month', created_ts)               AS sale_month,
        oi."product_id",
        SUM(oi."sale_price")                         AS total_sales,
        SUM(ii."cost")                               AS total_cost
    FROM order_items_clean            oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii
          ON ii."id" = oi."inventory_item_id"
    GROUP BY sale_month, oi."product_id"
),

profits AS (                         -- compute profit
    SELECT
        swc.sale_month,
        p."name"                                   AS product_name,
        swc."product_id",
        (swc.total_sales - swc.total_cost)         AS profit
    FROM sales_with_cost swc
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
          ON p."id" = swc."product_id"
),

ranked AS (                          -- rank products within each month
    SELECT
        sale_month,
        product_name,
        profit,
        DENSE_RANK() OVER (PARTITION BY sale_month
                           ORDER BY profit DESC)    AS rnk
    FROM profits
)

SELECT
    TO_CHAR(sale_month, 'YYYY-MM')    AS year_month,
    product_name,
    ROUND(profit, 4)                  AS profit
FROM ranked
WHERE rnk <= 3                        -- top‑3 only
ORDER BY
    sale_month,
    profit DESC,
    product_name;