/*  Top‑3 most profitable products per month (Jan‑2019 – Aug‑2022)               */
/*  Profit = Σ(sale_price) – Σ(cost) for completed, non‑returned order items     */

WITH valid_order_items AS (            -- remove cancelled / returned orders
    SELECT
        oi."id"                       AS order_item_id,
        oi."product_id",
        oi."inventory_item_id",
        oi."sale_price",
        TO_TIMESTAMP_NTZ(oi."created_at"/1000000)                            AS created_ts,
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at"/1000000))        AS month_start
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"       o
          ON oi."order_id" = o."order_id"
    WHERE oi."status"      NOT IN ('Cancelled','Returned')      -- item not cancelled/returned
      AND oi."returned_at" IS NULL
      AND o."status"       <> 'Cancelled'                       -- parent order not cancelled
      AND o."returned_at"  IS NULL
      AND TO_TIMESTAMP_NTZ(oi."created_at"/1000000)
            BETWEEN '2019-01-01' AND '2022-08-31 23:59:59'
),

product_month_profit AS (              -- aggregate sales & cost per product-month
    SELECT
        voi.month_start,
        p."name"                                                 AS product_name,
        SUM(voi."sale_price")                                    AS total_sales,
        SUM(ii."cost")                                           AS total_cost,
        SUM(voi."sale_price") - SUM(ii."cost")                   AS profit
    FROM valid_order_items                   voi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS"  ii
          ON voi."inventory_item_id" = ii."id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"         p
          ON voi."product_id" = p."id"
    GROUP BY
        voi.month_start,
        p."name"
),

ranked_products AS (                   -- rank products by monthly profit
    SELECT
        month_start,
        product_name,
        profit,
        ROW_NUMBER() OVER (PARTITION BY month_start ORDER BY profit DESC NULLS LAST) AS rn
    FROM product_month_profit
)

SELECT
    TO_CHAR(month_start,'YYYY-MM')   AS month,
    product_name,
    ROUND(profit,4)                  AS profit
FROM ranked_products
WHERE rn <= 3                        -- top 3 per month
ORDER BY month_start, rn;