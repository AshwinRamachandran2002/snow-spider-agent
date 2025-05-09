WITH 
total_sales AS (
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
        hdp."division", hsm."product_code"
),
ranked_sales AS (
    SELECT
        total_sales.*,
        ROW_NUMBER() OVER (
            PARTITION BY total_sales."division" 
            ORDER BY total_sales.total_quantity_sold DESC
        ) AS rn
    FROM
        total_sales
),
top3_sales AS (
    SELECT
        division,
        total_quantity_sold
    FROM
        ranked_sales
        WHERE
        rn <= 3
)
SELECT
    division,
    ROUND(AVG(total_quantity_sold), 4) AS Average_Quantity_Sold
FROM
    top3_sales
GROUP BY
    division;