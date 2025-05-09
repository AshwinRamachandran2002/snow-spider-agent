/*  Top 5 months (Aug-2022 – Nov-2023) with the largest MoM profit increase
    for Facebook-sourced, completed order items                       */
WITH monthly_profit AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000)   -- convert µs → TIMESTAMP
        )                                   AS "delivery_month",
        SUM(oi."sale_price" - ii."cost")    AS "monthly_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      AS oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           AS o
          ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"            AS u
          ON o."user_id" = u."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  AS ii
          ON oi."inventory_item_id" = ii."id"
    WHERE oi."status" = 'Complete'
      AND u."traffic_source" ILIKE '%Facebook%'
      AND o."created_at" BETWEEN 1659312000000000   -- 2022-08-01
                            AND 1701388799000000    -- 2023-11-30
      AND oi."delivered_at" IS NOT NULL             -- only delivered items
    GROUP BY 1
)
SELECT
    mp."delivery_month",
    mp."monthly_profit",
    mp."monthly_profit"
      - LAG(mp."monthly_profit") OVER (ORDER BY mp."delivery_month") AS "mom_increase"
FROM monthly_profit AS mp
QUALIFY "mom_increase" IS NOT NULL
ORDER BY "mom_increase" DESC NULLS LAST
LIMIT 5;