WITH monthly_profit AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ(oi."delivered_at" / 1000000)) AS "delivery_month",
        SUM(oi."sale_price" - ii."cost")                                   AS "monthly_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"       oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"             u  ON oi."user_id"            = u."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"   ii ON oi."inventory_item_id"  = ii."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"            o  ON oi."order_id"           = o."order_id"
    WHERE oi."status" = 'Complete'
      AND u."traffic_source" = 'Facebook'
      AND TO_TIMESTAMP_LTZ(o."created_at" / 1000000) >= '2022-08-01'
      AND TO_TIMESTAMP_LTZ(o."created_at" / 1000000) <  '2023-12-01'
    GROUP BY 1
),
monthly_diff AS (
    SELECT
        mp.*,
        mp."monthly_profit"
          - LAG(mp."monthly_profit") OVER (ORDER BY mp."delivery_month") AS "profit_increase"
    FROM monthly_profit mp
)
SELECT
    "delivery_month",
    "monthly_profit",
    "profit_increase"
FROM monthly_diff
ORDER BY "profit_increase" DESC NULLS LAST
LIMIT 5;