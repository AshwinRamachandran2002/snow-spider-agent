/* Top 5 months (Aug-2022 ‑ Nov-2023) with the largest month-over-month
   profit increase for Facebook-sourced, completed orders              */

WITH facebook_completed AS (   -- 1) keep only the relevant order-items
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000)      -- convert µs epoch → month
        )                                          AS "delivered_month",
        (oi."sale_price" - ii."cost")              AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           o
          ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"            u
          ON oi."user_id"  = u."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
          ON oi."inventory_item_id" = ii."id"
    WHERE  o."status"  = 'Complete'
      AND  u."traffic_source" ILIKE '%Facebook%'
      AND  o."created_at" BETWEEN 1659312000000000    /* 2022-08-01 00:00:00 */
                            AND   1701388799000000    /* 2023-11-30 23:59:59 */
      AND  oi."delivered_at" IS NOT NULL
),

monthly_profit AS (            -- 2) aggregate profit per delivery month
    SELECT
        "delivered_month",
        SUM("profit") AS "total_profit"
    FROM facebook_completed
    GROUP BY "delivered_month"
),

monthly_with_prev AS (         -- 3) calculate month-over-month increase
    SELECT
        "delivered_month",
        "total_profit",
        LAG("total_profit") OVER (ORDER BY "delivered_month")           AS "prev_month_profit",
        "total_profit" - LAG("total_profit") OVER (ORDER BY "delivered_month")
                                                                        AS "mom_increase"
    FROM monthly_profit
)

SELECT
    "delivered_month",
    "total_profit",
    "prev_month_profit",
    "mom_increase"
FROM   monthly_with_prev
WHERE  "mom_increase" IS NOT NULL
ORDER  BY "mom_increase" DESC NULLS LAST
LIMIT  5;