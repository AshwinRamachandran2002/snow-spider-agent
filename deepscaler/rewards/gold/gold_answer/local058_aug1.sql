-- Task: Can you provide a list of hardware product segments along with their unique product counts for 2020?
SELECT
    dp.segment,
    COUNT(DISTINCT fsm.product_code) AS unique_products_2020
FROM
    hardware_fact_sales_monthly fsm
JOIN
    hardware_dim_product dp ON fsm.product_code = dp.product_code
WHERE
    fsm.fiscal_year = 2020
GROUP BY
    dp.segment;