WITH total_per_product AS (
    SELECT hdp."division", hfs."product_code", SUM(hfs."sold_quantity") AS total_quantity_sold
    FROM "hardware_fact_sales_monthly" hfs
    JOIN "hardware_dim_product" hdp ON hfs."product_code" = hdp."product_code"
    WHERE hfs."date" BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY hdp."division", hfs."product_code"
),
ranked_products AS (
    SELECT "division", "product_code", total_quantity_sold,
           ROW_NUMBER() OVER (PARTITION BY "division" ORDER BY total_quantity_sold DESC) AS rn
    FROM total_per_product
),
top3_products AS (
    SELECT "division", "product_code"
    FROM ranked_products
    WHERE rn <= 3
)
SELECT tp."division", ROUND(AVG(hfs."sold_quantity"), 4) AS "Average_Quantity_Sold"
FROM "hardware_fact_sales_monthly" hfs
JOIN top3_products tp ON hfs."product_code" = tp."product_code"
WHERE hfs."date" BETWEEN '2021-01-01' AND '2021-12-31'
GROUP BY tp."division"
ORDER BY tp."division";