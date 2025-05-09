WITH monthly_profit AS (   -- profit per delivery month
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(oi."delivered_at" / 1e6), 'YYYY-MM') AS "delivery_month",
        SUM(oi."sale_price" - p."cost")                              AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p  ON oi."product_id" = p."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS        o  ON oi."order_id"  = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS         u  ON o."user_id"    = u."id"
    WHERE u."traffic_source" ILIKE '%Facebook%'                -- Facebook-sourced users
      AND oi."status" = 'Complete'                             -- completed order-items only
      AND TO_TIMESTAMP_NTZ(o."created_at" / 1e6)
              BETWEEN '2022-08-01' AND '2023-11-30 23:59:59'   -- orders created Aug-2022 → Nov-2023
      AND oi."delivered_at" IS NOT NULL                        -- ensure we have delivery time
    GROUP BY 1
),
mom_change AS (          -- month-over-month profit change
    SELECT
        "delivery_month",
        "total_profit",
        "total_profit"
        - LAG("total_profit") OVER (ORDER BY "delivery_month") AS "profit_change"
    FROM monthly_profit
)
SELECT
    "delivery_month",
    ROUND("profit_change", 4) AS "profit_change"
FROM mom_change
WHERE "profit_change" IS NOT NULL
ORDER BY "profit_change" DESC NULLS LAST    -- largest positive jumps first
LIMIT 5;