-- Top 5 months (Aug-2022 – Nov-2023) with the largest MoM profit increase
WITH monthly_profit AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000)) AS "delivery_month",
        SUM(oi."sale_price" - p."cost")                                     AS "profit"
    FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"        u
           ON oi."user_id" = u."id"
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
           ON oi."product_id" = p."id"
    WHERE  u."traffic_source"       ILIKE '%Facebook%'
      AND  oi."status"              ILIKE '%Complete%'
      AND  oi."delivered_at"        IS NOT NULL
      AND  TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
           BETWEEN '2022-08-01' AND '2023-11-30'
    GROUP BY 1
), profit_with_mom AS (
    SELECT
        "delivery_month",
        "profit",
        "profit" - LAG("profit") OVER (ORDER BY "delivery_month") AS "mom_increase"
    FROM monthly_profit
)
SELECT
    "delivery_month",
    ROUND("profit", 4)       AS "profit",
    ROUND("mom_increase", 4) AS "mom_increase"
FROM   profit_with_mom
WHERE  "mom_increase" IS NOT NULL
ORDER BY "mom_increase" DESC NULLS LAST
LIMIT 5;