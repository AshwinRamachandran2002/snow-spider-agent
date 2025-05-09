/* Top 5 months (Aug-2022 – Nov-2023) with the largest MoM profit increase
   for Facebook-sourced, completed & delivered orders            */

WITH "monthly_profit" AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("OI"."delivered_at" / 1000000)) AS "delivery_month",
        SUM("OI"."sale_price" - "II"."cost")                            AS "profit"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS       "OI"
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS            "O"
           ON "O"."order_id" = "OI"."order_id"
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS             "U"
           ON "U"."id" = "O"."user_id"
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS   "II"
           ON "II"."id" = "OI"."inventory_item_id"
    WHERE  "U"."traffic_source" = 'Facebook'                 -- Facebook shoppers
      AND  "OI"."status"       = 'Complete'                  -- completed order-items
      AND  "OI"."delivered_at" IS NOT NULL                   -- actually delivered
      AND  "O"."created_at" BETWEEN 1659312000000000         -- 2022-08-01
                               AND    1701388799000000       -- 2023-11-30 23:59:59
    GROUP BY 1
),
"mom_calc" AS (
    SELECT
        "delivery_month",
        "profit",
        "profit"
        - LAG("profit") OVER (ORDER BY "delivery_month")      AS "mom_increase"
    FROM "monthly_profit"
)
SELECT
    "delivery_month",
    ROUND("profit",       4) AS "profit",
    ROUND("mom_increase", 4) AS "mom_increase"
FROM   "mom_calc"
ORDER  BY "mom_increase" DESC NULLS LAST
LIMIT 5;