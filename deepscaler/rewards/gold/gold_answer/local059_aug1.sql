-- Task: For the calendar year 2021, what is the total quantity sold of each hardware product in each division?
SELECT 
    hdp."division",
    hsm."product_code",
    SUM(hsm."sold_quantity") AS total_quantity_sold
FROM 
    "hardware_fact_sales_monthly" AS hsm
JOIN 
    "hardware_dim_product" AS hdp
ON 
    hsm."product_code" = hdp."product_code"
WHERE
    hsm."date" BETWEEN '2021-01-01' AND '2021-12-31'
GROUP BY
    hdp."division", hsm."product_code";