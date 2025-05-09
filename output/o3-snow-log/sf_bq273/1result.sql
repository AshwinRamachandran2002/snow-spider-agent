WITH base AS (   -- Facebook-sourced, completed line items
    SELECT
        DATE_TRUNC(
            'MONTH',
            TO_TIMESTAMP(oi."delivered_at" / 1000000)   -- µs → s → timestamp
        )                                   AS delivery_month,
        (oi."sale_price" - ii."cost")       AS profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      AS oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           AS o
          ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"            AS u
          ON o."user_id"  = u."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  AS ii
          ON oi."inventory_item_id" = ii."id"
    WHERE oi."status"        ILIKE 'Complete'
      AND u."traffic_source" ILIKE 'Facebook'
      AND o."created_at" >= 1659312000000000   -- 2022-08-01
      AND o."created_at" <  1701388800000000   -- 2023-12-01
      AND oi."delivered_at" IS NOT NULL
),
month_profit AS (   -- total profit per delivery-month
    SELECT
        delivery_month,
        SUM(profit) AS month_profit
    FROM base
    WHERE delivery_month >= DATE '2022-08-01'
      AND delivery_month <  DATE '2023-12-01'
    GROUP BY delivery_month
),
with_prev AS (      -- month-over-month change
    SELECT
        delivery_month,
        month_profit,
        LAG(month_profit) OVER (ORDER BY delivery_month)               AS prev_month_profit,
        month_profit
          - LAG(month_profit) OVER (ORDER BY delivery_month)           AS mom_increase
    FROM month_profit
)
SELECT
    TO_CHAR(delivery_month, 'YYYY-MM') AS "delivery_month",
    ROUND(month_profit ,4)             AS "month_profit",
    ROUND(mom_increase ,4)             AS "mom_increase"
FROM   with_prev
ORDER  BY mom_increase DESC NULLS LAST
LIMIT 5;