WITH monthly_product_profit AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ(oi."created_at" / 1000000))          AS "month",
        oi."product_id",
        p."name"                                                                 AS "product_name",
        SUM(p."cost")                                                            AS "total_cost",
        SUM(oi."sale_price" - p."cost")                                          AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p
          ON oi."product_id" = p."id"
    -- consider all order items of any status, but only up to the end of Dec-2023
    WHERE TO_TIMESTAMP_LTZ(oi."created_at" / 1000000) < DATE '2024-01-01'
    GROUP BY 1, 2, 3
),
ranked AS (
    SELECT
        mp.*,
        RANK() OVER (PARTITION BY mp."month"
                     ORDER BY mp."total_profit" DESC)                            AS rn
    FROM monthly_product_profit mp
)
SELECT
    "month",
    "product_id",
    "product_name",
    "total_cost",
    "total_profit"
FROM ranked
WHERE rn = 1
ORDER BY "month";