WITH sales_2021 AS (
    SELECT 
        p."division",
        f."product_code",
        SUM(f."sold_quantity") AS total_qty
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY f
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT p
      ON f."product_code" = p."product_code"
    WHERE TO_DATE(f."date") BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY p."division", f."product_code"
),
ranked_products AS (
    SELECT
        "division",
        "product_code",
        total_qty,
        DENSE_RANK() OVER (PARTITION BY "division" ORDER BY total_qty DESC) AS rnk
    FROM sales_2021
),
top3 AS (
    SELECT 
        "division",
        total_qty
    FROM ranked_products
    WHERE rnk <= 3
)
SELECT
    "division",
    ROUND(AVG(total_qty), 4) AS average_quantity_sold
FROM top3
GROUP BY "division"
ORDER BY "division";