SELECT
    hdp."segment" AS "Segment",
    COUNT(DISTINCT CASE WHEN hfsm."fiscal_year" = 2020 THEN hfsm."product_code" END) AS "Unique_Product_Count_2020"
FROM
    "hardware_fact_sales_monthly" AS hfsm
JOIN
    "hardware_dim_product" AS hdp
    ON hfsm."product_code" = hdp."product_code"
GROUP BY
    hdp."segment"
HAVING
    COUNT(DISTINCT CASE WHEN hfsm."fiscal_year" = 2020 THEN hfsm."product_code" END) > 0
ORDER BY
    (
        (
            COUNT(DISTINCT CASE WHEN hfsm."fiscal_year" = 2021 THEN hfsm."product_code" END) -
            COUNT(DISTINCT CASE WHEN hfsm."fiscal_year" = 2020 THEN hfsm."product_code" END)
        ) * 100.0 /
        COUNT(DISTINCT CASE WHEN hfsm."fiscal_year" = 2020 THEN hfsm."product_code" END)
    ) DESC;