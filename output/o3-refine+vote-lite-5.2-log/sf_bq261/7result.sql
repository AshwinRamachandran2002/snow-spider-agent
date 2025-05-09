WITH product_month_profit AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("created_at" / 1000000))          AS "month_start",
        p."id"                                                            AS "product_id",
        p."name"                                                          AS "product_name",
        SUM(p."cost")                                                     AS "total_cost",
        SUM("sale_price" - p."cost")                                      AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS              oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS                 p
      ON oi."product_id" = p."id"
    /* keep every order item but exclude months >= 2024‑01 */
    WHERE TO_TIMESTAMP(oi."created_at" / 1000000) < '2024-01-01'
    GROUP BY
        DATE_TRUNC('month', TO_TIMESTAMP("created_at" / 1000000)),
        p."id",
        p."name"
),
ranked AS (
    SELECT
        "month_start",
        TO_CHAR("month_start", 'YYYY-MM')                                AS "order_month",
        "product_id",
        "product_name",
        "total_cost",
        "total_profit",
        ROW_NUMBER() OVER (PARTITION BY "month_start"
                           ORDER BY "total_profit" DESC, "product_id")  AS "rn"
    FROM product_month_profit
)
SELECT
    "order_month",
    "product_id",
    "product_name",
    "total_cost",
    "total_profit"
FROM ranked
WHERE "rn" = 1
ORDER BY "month_start";