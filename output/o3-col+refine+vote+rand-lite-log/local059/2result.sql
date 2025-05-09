WITH product_qty_2021 AS (
    SELECT  p."division",
            s."product_code",
            SUM(s."sold_quantity") AS total_qty_2021
    FROM   "hardware_fact_sales_monthly" AS s
    JOIN   "hardware_dim_product"        AS p
           ON p."product_code" = s."product_code"
    WHERE  s."date" BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP  BY p."division", s."product_code"
),
ranked_products AS (
    SELECT  division,
            product_code,
            total_qty_2021,
            RANK() OVER (PARTITION BY division ORDER BY total_qty_2021 DESC) AS rnk
    FROM    product_qty_2021
),
top_three_per_division AS (
    SELECT  division,
            total_qty_2021
    FROM    ranked_products
    WHERE   rnk <= 3
)
SELECT  division,
        ROUND(AVG(total_qty_2021), 2) AS avg_quantity_top3_2021
FROM    top_three_per_division
GROUP   BY division
ORDER   BY division;