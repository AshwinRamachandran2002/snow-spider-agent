WITH monthly_profit AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_LTZ(oi."delivered_at" / 1000000)
        )                                                     AS "delivery_month",
        SUM(oi."sale_price" - ii."cost")                     AS "monthly_profit"
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
            ON oi."inventory_item_id" = ii."id"
    JOIN
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           o
            ON oi."order_id" = o."order_id"
    JOIN
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"            u
            ON o."user_id" = u."id"
    WHERE
            u."traffic_source" ILIKE '%Facebook%'          -- Facebook-sourced buyers
        AND oi."status" = 'Complete'                       -- only completed order-items
        AND TO_TIMESTAMP_LTZ(o."created_at" / 1000000)     -- orders created in period
            BETWEEN '2022-08-01' AND '2023-11-30'
    GROUP BY
        1
),
mom_diff AS (
    SELECT
        mp.*,
        mp."monthly_profit"
          - LAG(mp."monthly_profit") OVER (ORDER BY mp."delivery_month")
                                                            AS "mom_increase"
    FROM
        monthly_profit mp
)
SELECT
    "delivery_month",
    "monthly_profit",
    "mom_increase"
FROM
    mom_diff
ORDER BY
    "mom_increase" DESC NULLS LAST
LIMIT 5;