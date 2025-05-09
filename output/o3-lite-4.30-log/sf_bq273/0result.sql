WITH monthly_profit AS (
    SELECT
        DATE_TRUNC('MONTH', TO_TIMESTAMP(o."delivered_at" / 1000000)) AS "delivery_month",
        SUM(oi."sale_price" - ii."cost")                              AS "profit"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"          o
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"           u
          ON o."user_id" = u."id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"     oi
          ON o."order_id" = oi."order_id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" ii
          ON oi."inventory_item_id" = ii."id"
    WHERE o."status" = 'Complete'
      AND oi."status" = 'Complete'
      AND u."traffic_source" = 'Facebook'
      AND TO_TIMESTAMP(o."created_at" / 1000000) BETWEEN '2022-08-01' AND '2023-11-30'
      AND o."delivered_at" IS NOT NULL
    GROUP BY 1
),
mom_change AS (
    SELECT
        "delivery_month",
        "profit" - LAG("profit") OVER (ORDER BY "delivery_month") AS "profit_increase"
    FROM monthly_profit
)
SELECT
    "delivery_month",
    ROUND("profit_increase", 4) AS "profit_increase"
FROM mom_change
WHERE "profit_increase" IS NOT NULL
ORDER BY "profit_increase" DESC NULLS LAST,
         "delivery_month"
LIMIT 5;