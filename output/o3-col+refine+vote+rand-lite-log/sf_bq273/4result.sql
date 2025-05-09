/* Top-5 months (Aug-2022 ‑ Nov-2023) with the largest MoM profit increase
   for “Complete” Facebook-sourced orders */

WITH monthly_profit AS (          -- 1.  monthly profit
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ(o."delivered_at", 6)) AS "delivery_month",
        SUM(oi."sale_price" - ii."cost")                           AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"          o
      ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"           u
      ON o."user_id" = u."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii
      ON oi."inventory_item_id" = ii."id"
    WHERE o."status" = 'Complete'
      AND oi."status" = 'Complete'
      AND u."traffic_source" ILIKE '%facebook%'                -- Facebook users only
      AND o."created_at" BETWEEN 1659312000000000              -- 2022-08-01
                           AND 1701302399000000                -- 2023-11-30
    GROUP BY 1
),
profit_mom AS (                   -- 2.  month-over-month change
    SELECT
        mp."delivery_month",
        mp."profit",
        mp."profit" - LAG(mp."profit") OVER (ORDER BY mp."delivery_month")
            AS "profit_increase"
    FROM monthly_profit mp
)
SELECT
    "delivery_month",
    "profit",
    "profit_increase"
FROM profit_mom
WHERE "profit_increase" IS NOT NULL
ORDER BY "profit_increase" DESC NULLS LAST   -- largest increases first
LIMIT 5;