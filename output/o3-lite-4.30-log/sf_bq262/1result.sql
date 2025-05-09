WITH base AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP(oi."created_at" / 1e6), 'YYYY-MM')  AS month,
        p."category"                                             AS product_category,
        COUNT(DISTINCT oi."order_id")                            AS total_orders,
        SUM(oi."sale_price")                                     AS total_revenue,
        SUM(oi."sale_price" - p."cost")                          AS total_profit
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"      p
      ON p."id" = oi."product_id"
    WHERE oi."created_at" BETWEEN 1559347200000000   -- 2019‑06‑01
                             AND 1577836800000000   -- 2020‑01‑01 (exclusive of 2020 data)
    GROUP BY 1, 2
)
SELECT
    month,
    product_category,
    total_orders,
    ROUND(total_revenue, 4)                                         AS total_revenue,
    ROUND(total_profit, 4)                                          AS total_profit,
    ROUND(
          (total_orders  / NULLIF(LAG(total_orders)  OVER (PARTITION BY product_category ORDER BY month), 0) - 1) * 100
         ,4)                                                        AS orders_mom_growth,
    ROUND(
          (total_revenue / NULLIF(LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY month), 0) - 1) * 100
         ,4)                                                        AS revenue_mom_growth,
    ROUND(
          (total_profit  / NULLIF(LAG(total_profit)  OVER (PARTITION BY product_category ORDER BY month), 0) - 1) * 100
         ,4)                                                        AS profit_mom_growth
FROM base
WHERE month BETWEEN '2019-07' AND '2019-12'   -- omit June in final output
ORDER BY month, product_category;