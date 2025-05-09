/*  Top-3 most profitable products per month
    (Jan-2019 ­– Aug-2022, cancelled / returned orders excluded)            */
WITH valid_order_items AS (       -- keep only items that actually generated revenue
    SELECT
        oi."id",
        oi."product_id",
        oi."inventory_item_id",
        oi."sale_price",
        oi."created_at",
        p."name"                                     AS product_name,
        ii."cost"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS         oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS              o
           ON oi."order_id" = o."order_id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS     ii
           ON oi."inventory_item_id" = ii."id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS            p
           ON oi."product_id" = p."id"
    WHERE  o."status"        NOT IN ('Cancelled' , 'Returned')    -- exclude cancelled / returned orders
      AND (oi."status" IS NULL OR oi."status" <> 'Cancelled')     -- exclude cancelled order-items
      AND oi."returned_at"  IS NULL                               -- exclude individually returned items
      AND oi."created_at"   IS NOT NULL
),
monthly_profit AS (
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP("created_at"/1000000)
                  )                          AS month_start,      -- first day of the month
        "product_id",
        product_name,
        SUM("sale_price")                   AS revenue,
        SUM("cost")                         AS cost,
        SUM("sale_price") - SUM("cost")     AS profit
    FROM   valid_order_items
    WHERE  DATE_TRUNC('month',
                      TO_TIMESTAMP("created_at"/1000000)
                     ) BETWEEN '2019-01-01' AND '2022-08-01'
    GROUP  BY month_start , "product_id" , product_name
),
ranked AS (
    SELECT
        month_start,
        product_name,
        profit,
        ROW_NUMBER() OVER (PARTITION BY month_start
                           ORDER BY profit DESC NULLS LAST) AS rn
    FROM monthly_profit
)
SELECT
    TO_CHAR(month_start , 'YYYY-MM')       AS month,
    product_name                           AS top_product_name,
    ROUND(profit , 4)                      AS profit
FROM   ranked
WHERE  rn <= 3                             -- top three per month
ORDER  BY month_start , profit DESC NULLS LAST;