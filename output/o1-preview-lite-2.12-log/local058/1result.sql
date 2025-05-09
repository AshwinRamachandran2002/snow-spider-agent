SELECT
    segment_counts_2020."segment" AS "Segment",
    segment_counts_2020."unique_products_sold_2020" AS "Unique_Product_Count_2020"
FROM
    (
        SELECT hdp."segment", COUNT(DISTINCT hfsm."product_code") AS "unique_products_sold_2020"
        FROM "hardware_fact_sales_monthly" AS hfsm
        JOIN "hardware_dim_product" AS hdp ON hfsm."product_code" = hdp."product_code"
        WHERE hfsm."fiscal_year" = 2020
        GROUP BY hdp."segment"
    ) AS segment_counts_2020
JOIN
    (
        SELECT hdp."segment", COUNT(DISTINCT hfsm."product_code") AS "unique_products_sold_2021"
        FROM "hardware_fact_sales_monthly" AS hfsm
        JOIN "hardware_dim_product" AS hdp ON hfsm."product_code" = hdp."product_code"
        WHERE hfsm."fiscal_year" = 2021
        GROUP BY hdp."segment"
    ) AS segment_counts_2021
ON segment_counts_2020."segment" = segment_counts_2021."segment"
ORDER BY
    ((CAST(segment_counts_2021."unique_products_sold_2021" AS FLOAT) - segment_counts_2020."unique_products_sold_2020") / segment_counts_2020."unique_products_sold_2020") DESC;