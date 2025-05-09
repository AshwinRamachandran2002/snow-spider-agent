WITH "filtered_orders" AS (      -- completed Facebook‑sourced orders
    SELECT
        oi."delivered_at",
        oi."sale_price",
        ii."cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"            o  ON o."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"             u  ON u."id"       = o."user_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"   ii ON ii."id"      = oi."inventory_item_id"
    WHERE  oi."status" = 'Complete'
      AND  u."traffic_source" = 'Facebook'
      AND  TO_DATE(TO_TIMESTAMP(o."created_at" / 1000000)) BETWEEN '2022-08-01' AND '2023-11-30'
      AND  oi."delivered_at" IS NOT NULL
),
"monthly_profit" AS (            -- profit per delivery month
    SELECT
        TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP("delivered_at" / 1000000)), 'YYYY-MM')
            AS "delivery_month",
        SUM("sale_price" - "cost") AS "profit"
    FROM "filtered_orders"
    GROUP BY "delivery_month"
    HAVING "delivery_month" BETWEEN '2022-08' AND '2023-11'
),
"profit_with_diff" AS (          -- month‑over‑month increase
    SELECT
        "delivery_month",
        "profit"                                                   AS "current_month_profit",
        LAG("profit") OVER (ORDER BY "delivery_month")             AS "previous_month_profit",
        "profit" - LAG("profit") OVER (ORDER BY "delivery_month")  AS "month_over_month_increase"
    FROM "monthly_profit"
)
SELECT
    "delivery_month",
    "current_month_profit",
    "previous_month_profit",
    "month_over_month_increase"
FROM "profit_with_diff"
WHERE "month_over_month_increase" IS NOT NULL
ORDER BY "month_over_month_increase" DESC NULLS LAST,
         "delivery_month"
LIMIT 5;