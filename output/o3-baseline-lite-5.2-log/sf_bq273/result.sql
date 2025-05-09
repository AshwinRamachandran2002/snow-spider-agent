WITH filtered_items AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("oi"."delivered_at" / 1e6))      AS delivery_month,
        ("oi"."sale_price" - "ii"."cost")                                 AS profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS          AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS               AS "o"
         ON "oi"."order_id" = "o"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS                AS "u"
         ON "oi"."user_id" = "u"."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS      AS "ii"
         ON "oi"."inventory_item_id" = "ii"."id"
    WHERE "o"."status"  = 'Complete'
      AND "oi"."status" = 'Complete'
      AND "u"."traffic_source" = 'Facebook'
      AND TO_DATE(TO_TIMESTAMP("o"."created_at" / 1e6))
            BETWEEN '2022-08-01' AND '2023-11-30'
      AND "oi"."delivered_at" IS NOT NULL
),
monthly_profit AS (
    SELECT
        delivery_month,
        SUM(profit) AS total_profit
    FROM filtered_items
    GROUP BY delivery_month
),
monthly_diff AS (
    SELECT
        delivery_month,
        total_profit,
        total_profit
          - LAG(total_profit) OVER (ORDER BY delivery_month) AS mom_increase
    FROM monthly_profit
    WHERE delivery_month BETWEEN '2022-08-01' AND '2023-11-30'
)
SELECT
    TO_VARCHAR(delivery_month, 'YYYY-MM')      AS month,
    ROUND(total_profit, 4)                     AS profit,
    ROUND(mom_increase, 4)                     AS profit_increase
FROM monthly_diff
ORDER BY profit_increase DESC NULLS LAST, month
LIMIT 5;