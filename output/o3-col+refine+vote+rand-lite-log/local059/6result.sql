WITH totals AS (
    /* total quantity per product within each division in calendar-year 2021 */
    SELECT  p.division,
            h.product_code,
            SUM(h.sold_quantity) AS total_qty
    FROM    hardware_fact_sales_monthly AS h
    JOIN    hardware_dim_product        AS p
           ON h.product_code = p.product_code
    WHERE   h.date BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY p.division, h.product_code
),
ranked AS (
    /* rank products inside each division by quantity sold */
    SELECT  division,
            product_code,
            total_qty,
            ROW_NUMBER() OVER (PARTITION BY division ORDER BY total_qty DESC) AS rn
    FROM    totals
),
top3 AS (
    /* keep the three best-selling products in every division */
    SELECT division, product_code, total_qty
    FROM   ranked
    WHERE  rn <= 3
)
SELECT ROUND(AVG(total_qty), 2) AS overall_avg_qty_top3_2021
FROM   top3;