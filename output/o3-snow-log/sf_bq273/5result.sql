WITH monthly_profit AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP(oi."delivered_at" / 1000000)
        )                                                AS "delivery_month",
        SUM(oi."sale_price" - ii."cost")                 AS "monthly_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           o  ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"            u  ON o."user_id"   = u."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii ON oi."inventory_item_id" = ii."id"
    WHERE  u."traffic_source" ILIKE '%Facebook%'             -- Facebook-sourced users
      AND  oi."status" = 'Complete'                          -- only completed order-items
      AND  TO_TIMESTAMP(o."created_at" / 1000000)
              BETWEEN '2022-08-01' AND '2023-11-30'          -- order creation window
    GROUP BY 1
),
profit_with_delta AS (
    SELECT
        "delivery_month",
        "monthly_profit",
        "monthly_profit" 
            - LAG("monthly_profit") OVER (ORDER BY "delivery_month") 
                                                        AS "mom_change"
    FROM monthly_profit
)
SELECT
    "delivery_month",
    "monthly_profit",
    "mom_change" AS "profit_increase_vs_prior_month"
FROM profit_with_delta
ORDER BY "mom_change" DESC NULLS LAST
LIMIT 5;