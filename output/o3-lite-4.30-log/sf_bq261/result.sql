WITH monthly_product_profit AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_LTZ(oi."created_at" / 1000000), 'YYYY-MM') AS "month",
        oi."product_id",
        SUM(p."cost")                           AS "total_cost",
        SUM(oi."sale_price" - p."cost")         AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
      ON p."id" = oi."product_id"
    WHERE oi."created_at" < 1704067200000000      -- before 2024‑01‑01
    GROUP BY 1, 2
),
ranked AS (
    SELECT
        mpp.*,
        ROW_NUMBER() OVER (PARTITION BY mpp."month" ORDER BY mpp."total_profit" DESC) AS rn
    FROM monthly_product_profit mpp
)
SELECT
    r."month",
    p."name"                       AS "product",
    ROUND(r."total_cost",   4)     AS "total_cost",
    ROUND(r."total_profit", 4)     AS "total_profit"
FROM ranked r
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
  ON p."id" = r."product_id"
WHERE r.rn = 1
ORDER BY r."month";