/*  Top-3 most profitable products for every month
    (Jan-2019 ‑ Aug-2022) –  profit = Σ(sale_price) – Σ(cost)
    Cancelled or returned orders / items are excluded
*/
WITH valid_order_items AS (   -- keep only items that were really sold
    SELECT  oi."id",
            oi."order_id",
            oi."product_id",
            oi."inventory_item_id",
            oi."sale_price",
            oi."created_at"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    INNER JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"     o
            ON o."order_id" = oi."order_id"
    WHERE   UPPER(oi."status") NOT IN ('CANCELLED','RETURNED')      -- item level
      AND   oi."returned_at" IS NULL
      AND   UPPER(o."status") <> 'CANCELLED'                        -- order level
      AND   o."returned_at" IS NULL
),
profit_per_item AS (          -- attach cost & derive month of sale
    SELECT  voi."product_id",
            voi."sale_price",
            inv."cost",
            DATE_TRUNC('month',
                       TO_TIMESTAMP(voi."created_at"/1000000)
                      )::DATE         AS order_month
    FROM    valid_order_items                              voi
    INNER JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" inv
            ON inv."id" = voi."inventory_item_id"
),
profit_per_product_month AS ( -- aggregate profit by product & month
    SELECT  ppi.order_month,
            pr."name"                          AS product_name,
            SUM(ppi."sale_price") - SUM(ppi."cost")  AS profit
    FROM    profit_per_item                       ppi
    INNER JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" pr
            ON pr."id" = ppi."product_id"
    WHERE   ppi.order_month BETWEEN '2019-01-01' AND '2022-08-01'
    GROUP BY ppi.order_month,
             pr."name"
),
ranked AS (                   -- rank products inside each month by profit
    SELECT  order_month,
            product_name,
            profit,
            ROW_NUMBER() OVER (PARTITION BY order_month
                               ORDER BY profit DESC NULLS LAST) AS rn
    FROM    profit_per_product_month
)
SELECT  order_month          AS "MONTH",
        product_name         AS "PRODUCT_NAME",
        ROUND(profit,4)      AS "PROFIT"
FROM    ranked
WHERE   rn <= 3
ORDER BY order_month,
         profit DESC NULLS LAST;