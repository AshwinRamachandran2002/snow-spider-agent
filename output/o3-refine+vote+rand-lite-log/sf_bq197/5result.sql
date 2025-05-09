WITH "MONTHLY_PRODUCT_SALES" AS (

    /* 1.  Aggregate monthly sales & revenue for every product that:
          • is linked to a non‑null brand
          • belongs to an order item whose status is ‘Complete’
          • occurred before July 2024                                             */
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP("oi"."created_at" / 1000000))          AS "SALE_MONTH",
        "p"."name"                                                    AS "PRODUCT_NAME",
        "p"."brand"                                                   AS "BRAND",
        "p"."category"                                                AS "CATEGORY",
        "oi"."status"                                                 AS "ORDER_STATUS",
        COUNT(*)                                                      AS "TOTAL_SALES",
        SUM("oi"."sale_price")                                        AS "TOTAL_REVENUE"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE "oi"."status" = 'Complete'
      AND "p"."brand"  IS NOT NULL
      AND DATE_TRUNC('month',
                     TO_TIMESTAMP("oi"."created_at" / 1000000))
          < DATE '2024-07-01'        -- keep only months prior to July 2024
    GROUP BY
        1, 2, 3, 4, 5
),

/* 2.  Rank products inside every month by
       • highest sales volume
       • then highest revenue (tiebreaker)                                 */
"RANKED" AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "SALE_MONTH"
                           ORDER BY "TOTAL_SALES" DESC,
                                    "TOTAL_REVENUE" DESC)  AS "RN"
    FROM "MONTHLY_PRODUCT_SALES"
)

/* 3.  Pick the single top performer per month and format the report        */
SELECT
    TO_CHAR("SALE_MONTH", 'YYYY-MM')          AS "MONTH",
    "PRODUCT_NAME",
    "BRAND",
    "CATEGORY",
    "TOTAL_SALES",
    ROUND("TOTAL_REVENUE", 2)                 AS "TOTAL_REVENUE",
    "ORDER_STATUS"
FROM "RANKED"
WHERE "RN" = 1
ORDER BY "SALE_MONTH";