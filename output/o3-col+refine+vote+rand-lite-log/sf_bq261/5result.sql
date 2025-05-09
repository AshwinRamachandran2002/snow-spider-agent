WITH monthly_product_profit AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1e6)) AS "month_start",
        p."name"                                                    AS "product_name",
        SUM(p."cost")                                               AS "total_cost",
        SUM(COALESCE(oi."sale_price", 0) - p."cost")                AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."created_at" < 1704067200000000          -- before 2024-01-01
    GROUP BY
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1e6)),
        p."name"
),
ranked_products AS (
    SELECT
        "month_start",
        "product_name",
        "total_cost",
        "total_profit",
        ROW_NUMBER() OVER (
            PARTITION BY "month_start"
            ORDER BY "total_profit" DESC NULLS LAST
        ) AS rn
    FROM monthly_product_profit
)
SELECT
    "month_start",
    "product_name",
    "total_cost",
    "total_profit"
FROM ranked_products
WHERE rn = 1
ORDER BY "month_start";