WITH order_sales_2020 AS (
    /* All items actually sold (not cancelled) in 2020 with their profit                     */
    SELECT
        oi."product_id",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))  AS month_start,
        (p."retail_price" - p."cost")                                    AS profit,
        p."name"                                                         AS product_name
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000), 'YYYY') = '2020'
      AND oi."status" <> 'Cancelled'        -- keep only real sales
), min_profit_per_month AS (
    /* Lowest profit recorded in each month                                                 */
    SELECT
        month_start,
        MIN(profit) AS min_profit
    FROM order_sales_2020
    GROUP BY month_start
)
SELECT
    TO_CHAR(m.month_start, 'YYYY-MM') AS month,
    o.product_name
FROM min_profit_per_month m
JOIN order_sales_2020   o
     ON  o.month_start = m.month_start
     AND o.profit      = m.min_profit           -- keep only the product(s) with lowest profit
ORDER BY m.month_start ASC,
         o.product_name;