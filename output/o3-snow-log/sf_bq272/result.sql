/*  Top-3 most profitable products for every month
    from Jan-2019 through Aug-2022 (exclusive of
    cancelled or returned orders/items)           */

WITH filtered_order_items AS (   -- keep only valid, in-period order items
    SELECT
        oi."product_id",
        oi."inventory_item_id",
        oi."sale_price",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)) AS order_month
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
          ON o."order_id" = oi."order_id"
    WHERE o."status" NOT IN ('Cancelled', 'Returned')         -- exclude unwanted orders
      AND oi."status" NOT IN ('Cancelled', 'Returned')        -- exclude unwanted items
      AND oi."created_at" IS NOT NULL
      AND DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))
            BETWEEN '2019-01-01'::DATE AND '2022-08-01'::DATE
),

profit_per_product_month AS (    -- aggregate revenue and cost -> profit
    SELECT
        f.order_month,
        f."product_id",
        p."name"                                       AS product_name,
        ROUND( SUM(f."sale_price")
             - SUM(COALESCE(ii."cost", 0)), 4)         AS profit
    FROM   filtered_order_items                       f
    LEFT  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii
           ON ii."id" = f."inventory_item_id"
    LEFT  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        p
           ON p."id" = f."product_id"
    GROUP  BY f.order_month, f."product_id", p."name"
),

ranked AS (                 -- pick the 3 highest-profit products each month
    SELECT
        order_month,
        product_name,
        profit,
        ROW_NUMBER() OVER (PARTITION BY order_month
                           ORDER BY profit DESC NULLS LAST) AS rn
    FROM profit_per_product_month
)

SELECT
    TO_CHAR(order_month, 'YYYY-MM') AS "MONTH",
    product_name                    AS "PRODUCT_NAME",
    profit                          AS "PROFIT"
FROM   ranked
WHERE  rn <= 3
ORDER  BY order_month,
         rn;