WITH monthly_product_sales AS (   /* 1.  Aggregate monthly sales for every product            */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000))   AS "month",
        "p"."name"                                                          AS "product_name",
        "p"."brand"                                                         AS "brand",
        "p"."category"                                                      AS "category",
        "oi"."status"                                                       AS "order_status",
        COUNT(*)                                                            AS "total_sales",
        SUM("oi"."sale_price")                                              AS "total_revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE "oi"."status" = 'Complete'                       /* only completed orders          */
      AND "p"."brand" IS NOT NULL                         /* require a non‑null brand        */
      AND DATE_TRUNC('month', TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000))
            < DATE '2024-07-01'                           /* months prior to July‑2024        */
    GROUP BY
        "month", "product_name", "brand", "category", "order_status"
),

ranked_monthly_best AS (       /* 2.  Rank products inside every month                      */
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "month"
                           ORDER BY "total_sales" DESC,
                                    "total_revenue" DESC)  AS "rn"
    FROM monthly_product_sales
)

SELECT
    TO_CHAR("month", 'YYYY-MM')            AS "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    ROUND("total_revenue", 2)              AS "total_revenue",
    "order_status"
FROM ranked_monthly_best
WHERE "rn" = 1                             /* 3.  Keep only the best‑selling product each month */
ORDER BY "month";