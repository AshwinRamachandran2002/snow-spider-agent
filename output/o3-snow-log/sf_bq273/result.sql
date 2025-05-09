/*  Top 5 months (Aug-2022 ‑ Nov-2023) with the largest MoM profit jump
    for Facebook-sourced, completed orders                       */
WITH monthly_profit AS (
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP_NTZ(o."delivered_at" / 1000000))  AS "delivery_month",
        SUM(oi."sale_price" - ii."cost")                          AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS        o
          ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS         u
          ON o."user_id" = u."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS ii
          ON oi."inventory_item_id" = ii."id"
    WHERE u."traffic_source" ILIKE '%facebook%'                     -- Facebook users
      AND o."status" = 'Complete'                                   -- completed orders
      AND o."created_at" BETWEEN 1659312000000000                   -- 2022-08-01 00:00:00
                             AND 1701388799000000                   -- 2023-11-30 23:59:59
      AND o."delivered_at" IS NOT NULL
    GROUP BY 1
    HAVING "delivery_month" BETWEEN DATE '2022-08-01'
                               AND DATE '2023-11-01'                -- Aug-22 … Nov-23
),
deltas AS (
    SELECT
        mp."delivery_month",
        mp."profit",
        mp."profit" - LAG(mp."profit") OVER (ORDER BY mp."delivery_month")
            AS "profit_increase"
    FROM monthly_profit mp
)
SELECT
    "delivery_month",
    ROUND("profit", 4)           AS "profit",
    ROUND("profit_increase", 4)  AS "profit_increase"
FROM deltas
ORDER BY "profit_increase" DESC NULLS LAST
LIMIT 5;