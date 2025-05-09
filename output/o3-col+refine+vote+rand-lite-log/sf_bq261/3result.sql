WITH monthly_product_profit AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))     AS "month_ts",
        oi."product_id",
        SUM(p."cost")                                                   AS "total_cost",
        SUM(oi."sale_price" - p."cost")                                 AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p
      ON oi."product_id" = p."id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) < DATE '2024-01-01'
    GROUP BY 1, 2
),
ranked_products AS (
    SELECT
        mpp.*,
        ROW_NUMBER() OVER (PARTITION BY mpp."month_ts"
                           ORDER BY mpp."total_profit" DESC NULLS LAST) AS rn
    FROM monthly_product_profit mpp
)
SELECT
    rp."month_ts",
    pr."name"        AS "product_name",
    rp."total_cost",
    rp."total_profit"
FROM ranked_products                rp
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS  pr
  ON rp."product_id" = pr."id"
WHERE rp.rn = 1
ORDER BY rp."month_ts";