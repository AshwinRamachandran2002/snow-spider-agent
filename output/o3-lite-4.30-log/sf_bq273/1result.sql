/*  Top‑5 months (Aug‑2022 ⇢ Nov‑2023) with the largest MoM profit increase
    for Facebook‑sourced, COMPLETED orders.                        */
WITH fb_orders AS (
    SELECT  o."order_id",
            DATE_TRUNC(
                'month',
                TO_TIMESTAMP(o."delivered_at" / 1000000)
            )                                    AS "delivery_month"
    FROM  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"  o
    JOIN  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"   u
          ON o."user_id" = u."id"
    WHERE u."traffic_source" = 'Facebook'
      AND o."status"        = 'Complete'
      AND TO_TIMESTAMP(o."created_at" / 1000000)
          BETWEEN '2022-08-01' AND '2023-11-30 23:59:59'
      AND o."delivered_at" IS NOT NULL
),
profit_by_month AS (
    SELECT  f."delivery_month",
            SUM(oi."sale_price" - p."cost")      AS "total_profit"
    FROM   fb_orders f
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
           ON f."order_id" = oi."order_id"
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"    p
           ON oi."product_id" = p."id"
    GROUP  BY f."delivery_month"
),
profit_delta AS (
    SELECT  "delivery_month",
            "total_profit",
            "total_profit"
            - LAG("total_profit") OVER (ORDER BY "delivery_month")
                                              AS "profit_increase"
    FROM    profit_by_month
)
SELECT  "delivery_month",
        ROUND("profit_increase", 4)  AS "profit_increase"
FROM    profit_delta
ORDER BY "profit_increase" DESC NULLS LAST,
         "delivery_month"
LIMIT 5;