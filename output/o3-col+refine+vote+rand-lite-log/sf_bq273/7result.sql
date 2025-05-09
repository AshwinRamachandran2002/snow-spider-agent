WITH month_profit AS (           -- 1. Profit per delivery-month
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(o."delivered_at" / 1000000), 'YYYY-MM')      AS "delivery_month",
        SUM(oi."sale_price" - ii."cost")                                      AS "profit"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
          ON oi."inventory_item_id" = ii."id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           o
          ON oi."order_id" = o."order_id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"            u
          ON o."user_id" = u."id"
    WHERE u."traffic_source" ILIKE '%facebook%'                  -- Facebook users
      AND o."status" = 'Complete'                                -- only completed orders
      AND o."created_at" BETWEEN 1659312000000000                -- 01-Aug-2022
                              AND 1701388799000000               -- 30-Nov-2023
      AND o."delivered_at" IS NOT NULL
    GROUP BY 1
),
month_change AS (               -- 2. Month-over-month change
    SELECT
        "delivery_month",
        "profit",
        "profit" - LAG("profit") OVER (ORDER BY "delivery_month") AS "profit_change"
    FROM month_profit
    WHERE "delivery_month" BETWEEN '2022-08' AND '2023-11'
)
-- 3. Top-5 months with the largest positive profit increase
SELECT
    "delivery_month",
    ROUND("profit",         4) AS "total_profit",
    ROUND("profit_change",  4) AS "month_over_month_profit_change"
FROM   month_change
WHERE  "profit_change" IS NOT NULL
ORDER BY "profit_change" DESC NULLS LAST
LIMIT 5;