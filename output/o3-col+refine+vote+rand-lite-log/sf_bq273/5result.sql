/*  Top-5 months (Aug-2022 ‑ Nov-2023) with the largest MoM profit jump
    for Facebook-sourced, completed orders.
*/
WITH facebook_completed AS (   -- individual order-line profits
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000), 'YYYY-MM') AS "delivery_month",
        (oi."sale_price" - p."cost")                                      AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"        u
         ON oi."user_id" = u."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
         ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
      AND u."traffic_source" ILIKE '%facebook%'
      AND oi."delivered_at" IS NOT NULL
      -- keep orders CREATED between 1-Aug-2022 and 30-Nov-2023
      AND TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
            BETWEEN '2022-08-01' AND '2023-11-30 23:59:59'
      -- keep deliveries between Aug-2022 and Nov-2023
      AND TO_CHAR(TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000), 'YYYY-MM')
            BETWEEN '2022-08' AND '2023-11'
),
monthly_profit AS (             -- aggregate to delivery month
    SELECT
        "delivery_month",
        SUM("profit") AS "monthly_profit"
    FROM facebook_completed
    GROUP BY "delivery_month"
),
with_mom AS (                   -- month-over-month change
    SELECT
        "delivery_month",
        "monthly_profit",
        "monthly_profit"
            - LAG("monthly_profit") OVER (ORDER BY "delivery_month") AS "mom_change"
    FROM monthly_profit
)
SELECT
    "delivery_month",
    ROUND("monthly_profit", 4) AS "monthly_profit",
    ROUND("mom_change",    4) AS "mom_change"
FROM with_mom
WHERE "mom_change" IS NOT NULL
ORDER BY "mom_change" DESC NULLS LAST
LIMIT 5;