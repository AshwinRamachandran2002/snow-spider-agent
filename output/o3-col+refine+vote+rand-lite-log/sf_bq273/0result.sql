/* Top 5 months (Aug-2022 – Nov-2023) with the largest MoM profit jump
   for Facebook-sourced, “Complete” orders.                       */
WITH monthly_profits AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(oi."delivered_at" / 1e6)
        )                                              AS "delivery_month",
        SUM(oi."sale_price" - ii."cost")              AS "monthly_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
         ON oi."inventory_item_id" = ii."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           o
         ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"            u
         ON o."user_id" = u."id"
    WHERE o."status" = 'Complete'
      AND u."traffic_source" = 'Facebook'
      AND TO_TIMESTAMP_NTZ(o."created_at" / 1e6)
            BETWEEN '2022-08-01' AND '2023-11-30 23:59:59'
      AND oi."delivered_at" IS NOT NULL
    GROUP BY 1
)

SELECT
    "delivery_month",
    "monthly_profit",
    "monthly_profit"
      - LAG("monthly_profit") OVER (ORDER BY "delivery_month")  AS "mom_profit_change"
FROM monthly_profits
WHERE "delivery_month" BETWEEN '2022-08-01' AND '2023-11-30'
ORDER BY "mom_profit_change" DESC NULLS LAST
LIMIT 5;