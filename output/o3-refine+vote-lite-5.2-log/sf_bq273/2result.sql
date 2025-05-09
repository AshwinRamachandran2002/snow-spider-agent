WITH monthly_profit AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("oi"."delivered_at" / 1000000))          AS "delivery_month",
        SUM("oi"."sale_price" - "ii"."cost")                                      AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           AS "o"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"            AS "u"
         ON "o"."user_id" = "u"."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      AS "oi"
         ON "o"."order_id" = "oi"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  AS "ii"
         ON "oi"."inventory_item_id" = "ii"."id"
    WHERE  "u"."traffic_source" = 'Facebook'             -- Facebook‑sourced customers
      AND  "o"."status"        = 'Complete'              -- completed orders
      AND  "oi"."status"       = 'Complete'
      AND  "oi"."delivered_at" IS NOT NULL               -- must be delivered
      AND  TO_TIMESTAMP("o"."created_at" / 1000000) >= '2022-08-01'::date
      AND  TO_TIMESTAMP("o"."created_at" / 1000000) <  '2023-12-01'::date
    GROUP BY 1
), monthly_change AS (
    SELECT
        "delivery_month",
        "profit",
        "profit" - LAG("profit") OVER (ORDER BY "delivery_month") AS "mom_increase"
    FROM monthly_profit
)
SELECT
    "delivery_month",
    "profit",
    "mom_increase"
FROM monthly_change
WHERE "mom_increase" IS NOT NULL
ORDER BY "mom_increase" DESC NULLS LAST, "delivery_month"
LIMIT 5;