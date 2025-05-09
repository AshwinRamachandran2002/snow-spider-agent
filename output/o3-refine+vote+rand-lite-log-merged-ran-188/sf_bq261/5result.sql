WITH order_item_monthly AS (
    /* 1.  Aggregate cost and profit for every product within each calendar month
          (based on the order‑item creation timestamp).                               */
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ("created_at" / 1000000)
        )                                        AS "month",
        "product_id",
        SUM(P."cost")                            AS "total_cost",
        SUM("sale_price" - P."cost")             AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      OI
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         P
          ON OI."product_id" = P."id"
    WHERE TO_TIMESTAMP_NTZ("created_at" / 1000000) < '2024-01-01'      -- prior to Jan‑2024
    GROUP BY
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at" / 1000000)),
        "product_id"
),
ranked AS (
    /* 2.  Rank products inside every month by total profit (highest first).            */
    SELECT
        "month",
        "product_id",
        "total_cost",
        "total_profit",
        ROW_NUMBER() OVER (
            PARTITION BY "month"
            ORDER BY "total_profit" DESC, "product_id"
        ) AS rn
    FROM order_item_monthly
)
SELECT
    TO_CHAR("month", 'YYYY-MM')                  AS "MONTH",
    r."product_id"                               AS "PRODUCT_ID",
    p."name"                                     AS "PRODUCT_NAME",
    ROUND(r."total_cost",   4)                   AS "TOTAL_COST",
    ROUND(r."total_profit", 4)                   AS "TOTAL_PROFIT"
FROM ranked r
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"  p
     ON r."product_id" = p."id"
WHERE r.rn = 1                                              -- keep only the top‑profit product per month
ORDER BY "month";