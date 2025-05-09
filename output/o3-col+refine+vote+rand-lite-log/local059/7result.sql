WITH product_totals AS (
    /* total quantity sold per product in 2021 */
    SELECT dp."division",
           sm."product_code",
           SUM(sm."sold_quantity") AS total_qty
    FROM   "hardware_fact_sales_monthly" AS sm
    JOIN   "hardware_dim_product"        AS dp
           ON sm."product_code" = dp."product_code"
    WHERE  sm."date" LIKE '2021-%'               -- calendar year-2021
    GROUP BY dp."division", sm."product_code"
),
ranked_products AS (
    /* rank products within each division by 2021 sales */
    SELECT pt.*,
           RANK() OVER (PARTITION BY pt."division"
                        ORDER BY pt.total_qty DESC) AS rnk
    FROM   product_totals AS pt
),
top3_per_division AS (
    /* keep only the top-3 products per division */
    SELECT "division",
           total_qty
    FROM   ranked_products
    WHERE  rnk <= 3
)
SELECT   "division",
         ROUND(AVG(total_qty), 4)  AS avg_qty_top3_2021
FROM     top3_per_division
GROUP BY "division";