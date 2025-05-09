WITH order_items_enriched AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("created_at" / 1000000))          AS month_start
      , oi."product_id"
      , SUM(COALESCE(oi."sale_price",0))                                   AS total_sales
      , SUM(p."cost")                                                      AS total_cost
      , SUM(COALESCE(oi."sale_price",0) - p."cost")                        AS total_profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE "created_at" IS NOT NULL
      AND DATE_TRUNC('month', TO_TIMESTAMP("created_at" / 1000000)) < '2024-01-01'
    GROUP BY
        month_start,
        oi."product_id"
),
ranked_products AS (
    SELECT
        month_start,
        "product_id",
        total_cost,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY month_start
                           ORDER BY total_profit DESC NULLS LAST) AS rnk
    FROM order_items_enriched
)
SELECT
    TO_CHAR(month_start, 'YYYY-MM')                           AS month
  , p."name"                                                  AS product_name
  , ROUND(total_cost , 4)                                     AS total_cost
  , ROUND(total_profit, 4)                                    AS total_profit
FROM ranked_products rp
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
     ON rp."product_id" = p."id"
WHERE rp.rnk = 1
ORDER BY month_start;