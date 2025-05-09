WITH monthly_product_profit AS (

    /*--------------------------------------------------------------------
      1.  Aggregate per product & month
          - month_start : DATE   (easy filtering & ordering)
          - month       : TEXT   ('YYYY-MM' for display)
          - total_cost  : Σ product unit-costs
          - total_profit: Σ (sale_price – cost)
    --------------------------------------------------------------------*/
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1e6))                             AS "month_start",
        TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1e6)), 'YYYY-MM')         AS "month",
        oi."product_id",
        SUM(p."cost")                                                                        AS "total_cost",
        SUM(oi."sale_price" - p."cost")                                                      AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    GROUP BY
        "month_start",
        "month",
        oi."product_id"
    HAVING
        "month_start" < DATE '2024-01-01'   -- keep only months prior to Jan-2024
),

/*--------------------------------------------------------------------
  2.  For every month, keep the product with the highest total_profit
--------------------------------------------------------------------*/
ranked AS (
    SELECT
        "month_start",
        "month",
        "product_id",
        "total_cost",
        "total_profit",
        ROW_NUMBER() OVER (PARTITION BY "month_start" ORDER BY "total_profit" DESC) AS "rn"
    FROM monthly_product_profit
)

SELECT
    r."month",
    r."product_id",
    p."name"                                                          AS "product_name",
    ROUND(r."total_cost",   4)                                        AS "total_cost",
    ROUND(r."total_profit", 4)                                        AS "total_profit"
FROM ranked r
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON r."product_id" = p."id"
WHERE r."rn" = 1                        -- top-profit product per month
ORDER BY r."month_start";