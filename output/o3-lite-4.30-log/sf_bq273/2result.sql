WITH "monthly_profit" AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ("oi"."delivered_at" / 1000000), 'YYYY-MM')   AS "delivery_month",
        SUM("oi"."sale_price" - "p"."cost")                                   AS "profit"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"        AS "u"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"       AS "o"
          ON "o"."user_id" = "u"."id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  AS "oi"
          ON "oi"."order_id" = "o"."order_id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     AS "p"
          ON "p"."id" = "oi"."product_id"
    WHERE "u"."traffic_source" = 'Facebook'
      AND "o"."status"  = 'Complete'
      AND "oi"."status" = 'Complete'
      AND "o"."created_at" BETWEEN 1659312000000000            -- 2022‑08‑01
                               AND    1701302399000000         -- 2023‑11‑30
    GROUP BY 1
),
"monthly_change" AS (
    SELECT
        "delivery_month",
        "profit" - LAG("profit") OVER (ORDER BY "delivery_month") AS "profit_increase"
    FROM "monthly_profit"
)
SELECT
    "delivery_month",
    ROUND("profit_increase", 4) AS "profit_increase"
FROM "monthly_change"
WHERE "profit_increase" IS NOT NULL
  AND "delivery_month" BETWEEN '2022-08' AND '2023-11'
ORDER BY "profit_increase" DESC NULLS LAST,
         "delivery_month"
LIMIT 5;