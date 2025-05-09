WITH monthly AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."delivered_at" / 1000000)) AS "delivery_month",
        SUM(oi."sale_price" - ii."cost")                                   AS "monthly_profit"
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS          o
        JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi  ON o."order_id" = oi."order_id"
        JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS ii ON oi."inventory_item_id" = ii."id"
        JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS       u   ON o."user_id" = u."id"
    WHERE
        u."traffic_source" ILIKE '%Facebook%'
        AND o."status"   = 'Complete'
        AND oi."status"  = 'Complete'
        AND TO_TIMESTAMP_NTZ(o."created_at" / 1000000)::DATE 
            BETWEEN '2022-08-01' AND '2023-11-30'
    GROUP BY
        1
)

SELECT
    "delivery_month",
    "monthly_profit",
    "monthly_profit" 
      - LAG("monthly_profit") OVER (ORDER BY "delivery_month") AS "profit_mom_change"
FROM
    monthly
QUALIFY
    "profit_mom_change" IS NOT NULL
ORDER BY
    "profit_mom_change" DESC NULLS LAST
LIMIT 5;