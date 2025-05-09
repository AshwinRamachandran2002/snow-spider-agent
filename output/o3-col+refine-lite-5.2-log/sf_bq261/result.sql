-- For every month before Jan‑2024, find the product with the greatest total profit
SELECT
    t."month",
    p."name"          AS "product_name",
    t."total_cost",
    t."total_profit"
FROM (
    /* 1)  Aggregate profit & cost by month‑product
       2)  Rank products within each month by total profit */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))              AS "month",
        oi."product_id",
        SUM(pr."cost")                                                            AS "total_cost",
        SUM(oi."sale_price" - pr."cost")                                          AS "total_profit",
        RANK() OVER (
            PARTITION BY DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))
            ORDER BY SUM(oi."sale_price" - pr."cost") DESC
        )                                                                         AS "rnk"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     pr
      ON oi."product_id" = pr."id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) < '2024-01-01'
    GROUP BY 1, 2
) t
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
  ON t."product_id" = p."id"
WHERE t."rnk" = 1
ORDER BY t."month";