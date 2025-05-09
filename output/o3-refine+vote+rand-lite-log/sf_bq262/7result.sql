/*  Monthly sales report (Jul‑Dec 2019) with MoM growth,
    using Jun‑2019 as the base month                                   */

WITH order_data AS (   -- explode every item that was part of an order
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ("ORDERS"."created_at" / 1000000)
        )                                  AS "MONTH",
        "PRODUCTS"."category"              AS "CATEGORY",
        "ORDERS"."order_id"                AS "ORDER_ID",
        "ORDER_ITEMS"."sale_price"         AS "SALE_PRICE",
        ("ORDER_ITEMS"."sale_price" - "PRODUCTS"."cost")  AS "PROFIT"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  AS "ORDER_ITEMS"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS       AS "ORDERS"
          ON "ORDER_ITEMS"."order_id" = "ORDERS"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     AS "PRODUCTS"
          ON "ORDER_ITEMS"."product_id" = "PRODUCTS"."id"
    WHERE TO_TIMESTAMP_NTZ("ORDERS"."created_at" / 1000000)
          BETWEEN '2019-06-01'::date AND '2019-12-31'::date        -- Jun‑Dec 2019
),
monthly_totals AS (    -- aggregate per month & category
    SELECT
        "MONTH",
        "CATEGORY",
        COUNT(DISTINCT "ORDER_ID")          AS "TOTAL_ORDERS",
        SUM("SALE_PRICE")                   AS "TOTAL_REVENUE",
        SUM("PROFIT")                       AS "TOTAL_PROFIT"
    FROM order_data
    GROUP BY "MONTH", "CATEGORY"
),
with_growth AS (       -- add previous‑month values for MoM calculation
    SELECT
        "MONTH",
        "CATEGORY",
        "TOTAL_ORDERS",
        "TOTAL_REVENUE",
        "TOTAL_PROFIT",
        LAG("TOTAL_ORDERS")  OVER (PARTITION BY "CATEGORY" ORDER BY "MONTH") AS "PREV_ORDERS",
        LAG("TOTAL_REVENUE") OVER (PARTITION BY "CATEGORY" ORDER BY "MONTH") AS "PREV_REVENUE",
        LAG("TOTAL_PROFIT")  OVER (PARTITION BY "CATEGORY" ORDER BY "MONTH") AS "PREV_PROFIT"
    FROM monthly_totals
)
SELECT
    TO_CHAR("MONTH", 'YYYY-MM')                                         AS "MONTH",
    "CATEGORY",
    "TOTAL_ORDERS",
    "TOTAL_REVENUE",
    "TOTAL_PROFIT",
    ROUND( ("TOTAL_ORDERS" - "PREV_ORDERS") / NULLIF("PREV_ORDERS",0), 4)  AS "ORDERS_MOM_GROWTH",
    ROUND( ("TOTAL_REVENUE" - "PREV_REVENUE") / NULLIF("PREV_REVENUE",0),4)AS "REVENUE_MOM_GROWTH",
    ROUND( ("TOTAL_PROFIT" - "PREV_PROFIT") / NULLIF("PREV_PROFIT",0),4)   AS "PROFIT_MOM_GROWTH"
FROM with_growth
WHERE "MONTH" >= '2019-07-01'::date      -- omit June from final output
ORDER BY "MONTH" ASC, "CATEGORY" ASC;