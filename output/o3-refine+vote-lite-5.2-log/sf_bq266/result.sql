WITH order_sales_2020 AS (          -- products that recorded at least one sale in 2020
    SELECT DISTINCT
           DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at" / 1000000)) AS "sale_month",
           "product_id"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE  YEAR(TO_TIMESTAMP_NTZ("created_at" / 1000000)) = 2020
),
profit_per_product AS (             -- profit per product (rounded to 4 decimals)
    SELECT
           os."sale_month",
           p."id"                              AS "product_id",
           p."name"                            AS "product_name",
           ROUND(p."retail_price" - p."cost", 4) AS "profit"
    FROM   order_sales_2020  os
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"  p
           ON os."product_id" = p."id"
),
min_profit_per_month AS (           -- lowest profit recorded each month
    SELECT
           "sale_month",
           MIN("profit") AS "min_profit"
    FROM   profit_per_product
    GROUP  BY "sale_month"
)
SELECT
       TO_CHAR(pp."sale_month", 'YYYY-MM') AS "month",
       pp."product_name"
FROM   profit_per_product  pp
JOIN   min_profit_per_month mp
       ON  pp."sale_month" = mp."sale_month"
       AND pp."profit"     = mp."min_profit"
ORDER BY
       pp."sale_month",
       pp."product_name";