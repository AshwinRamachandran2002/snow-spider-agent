/* Top‑5 delivery months (Aug‑2022 – Nov‑2023) with the largest MoM profit increases
   for Facebook‑sourced, completed orders                                 */

WITH monthly_profit AS (
    SELECT
        /* Month when the item was delivered                          */
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_LTZ("oi"."delivered_at" / 1e6)
        )                                               AS "delivery_month",

        /* Profit = sale_price – product cost                         */
        SUM("oi"."sale_price" - "p"."cost")             AS "monthly_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      AS "p"
         ON "oi"."product_id" = "p"."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"        AS "o"
         ON "oi"."order_id" = "o"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"         AS "u"
         ON "oi"."user_id" = "u"."id"
    WHERE "u"."traffic_source" ILIKE '%facebook%'          -- Facebook‑sourced users
      AND "o"."status" = 'Complete'                       -- Completed orders
      AND "o"."created_at" BETWEEN 1659312000000000       -- 2022‑08‑01 00:00:00
                             AND 1701388799000000         -- 2023‑11‑30 23:59:59
      AND "oi"."delivered_at" IS NOT NULL                 -- Must be delivered
    GROUP BY 1
)

SELECT
    "delivery_month",
    "monthly_profit",
    /* Month‑over‑month profit change                               */
    "monthly_profit"
      - LAG("monthly_profit") OVER (ORDER BY "delivery_month") 
        AS "profit_delta_vs_prior_month"
FROM monthly_profit
QUALIFY "profit_delta_vs_prior_month" IS NOT NULL           -- Exclude the first month
ORDER BY "profit_delta_vs_prior_month" DESC NULLS LAST,      -- Largest increases first
         "delivery_month"
LIMIT 5;