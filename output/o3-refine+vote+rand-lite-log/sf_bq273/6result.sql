WITH base AS (   -- every Facebook‑sourced, completed order line created Aug‑22 … Nov‑23
    SELECT
        DATE_TRUNC(
            'MONTH',
            TO_TIMESTAMP(oi."delivered_at" / 1e6)
        )                                           AS delivery_month,
        (oi."sale_price" - ii."cost")               AS profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"        oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"             o
          ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"              u
          ON o."user_id"  = u."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"    ii
          ON oi."inventory_item_id" = ii."id"
    WHERE  oi."status"       = 'Complete'
      AND  u."traffic_source" = 'Facebook'
      AND  TO_TIMESTAMP(o."created_at" / 1e6) >= '2022-08-01'
      AND  TO_TIMESTAMP(o."created_at" / 1e6) <  '2023-12-01'     -- up to 30‑Nov‑23 inclusive
      AND  oi."delivered_at" IS NOT NULL
),

monthly_profit AS (          -- total profit by delivery month
    SELECT
        delivery_month,
        SUM(profit) AS total_profit
    FROM base
    GROUP BY delivery_month
),

with_deltas AS (             -- month‑over‑month change
    SELECT
        delivery_month,
        total_profit,
        LAG(total_profit) OVER (ORDER BY delivery_month)             AS prev_month_profit,
        total_profit
        - LAG(total_profit) OVER (ORDER BY delivery_month)           AS profit_increase
    FROM monthly_profit
)

SELECT
    delivery_month,
    total_profit,
    prev_month_profit,
    profit_increase
FROM with_deltas
WHERE delivery_month BETWEEN '2022-08-01' AND '2023-11-01'   -- months Aug‑22 … Nov‑23
QUALIFY profit_increase IS NOT NULL
ORDER BY profit_increase DESC NULLS LAST, delivery_month
LIMIT 5;