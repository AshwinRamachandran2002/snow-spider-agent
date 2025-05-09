WITH yr20 AS (
    SELECT hdp."segment",
           COUNT(DISTINCT hfs."product_code") AS "uniq_prod_2020"
    FROM   "hardware_fact_sales_monthly" AS hfs
    JOIN   "hardware_dim_product"        AS hdp
           ON hdp."product_code" = hfs."product_code"
    WHERE  hfs."fiscal_year" = 2020
    GROUP BY hdp."segment"
),
yr21 AS (
    SELECT hdp."segment",
           COUNT(DISTINCT hfs."product_code") AS "uniq_prod_2021"
    FROM   "hardware_fact_sales_monthly" AS hfs
    JOIN   "hardware_dim_product"        AS hdp
           ON hdp."product_code" = hfs."product_code"
    WHERE  hfs."fiscal_year" = 2021
    GROUP BY hdp."segment"
)
SELECT  yr20."segment",
        yr20."uniq_prod_2020"
FROM    yr20
LEFT JOIN yr21 USING ("segment")
ORDER BY
    CAST(yr21."uniq_prod_2021" - yr20."uniq_prod_2020" AS REAL)
    / NULLIF(yr20."uniq_prod_2020", 0) DESC;