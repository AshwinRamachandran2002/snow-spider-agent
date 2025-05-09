WITH "monthly_product" AS (
    SELECT
        TO_CHAR(
            TO_DATE(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)),
            'YYYY-MM'
        )                                    AS "month",
        oi."product_id",
        SUM(p."cost")                        AS "total_cost",
        SUM(oi."sale_price" - p."cost")      AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
      ON oi."product_id" = p."id"
    WHERE TO_DATE(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)) < '2024-01-01'
    GROUP BY 1, 2
),
"ranked" AS (
    SELECT
        mp."month",
        mp."product_id",
        mp."total_cost",
        mp."total_profit",
        RANK() OVER (PARTITION BY mp."month"
                     ORDER BY mp."total_profit" DESC)      AS "rk"
    FROM "monthly_product" mp
)
SELECT
    r."month",
    prod."name"                                       AS "product",
    ROUND(r."total_cost",   4)                        AS "total_cost",
    ROUND(r."total_profit", 4)                        AS "total_profit"
FROM "ranked" r
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" prod
  ON r."product_id" = prod."id"
WHERE r."rk" = 1
ORDER BY r."month";