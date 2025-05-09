WITH yr20 AS (
    SELECT d."segment",
           COUNT(DISTINCT f."product_code") AS "unique_products_2020"
    FROM   "hardware_fact_sales_monthly" AS f
    JOIN   "hardware_dim_product"        AS d
           ON f."product_code" = d."product_code"
    WHERE  f."fiscal_year" = 2020
    GROUP BY d."segment"
),
yr21 AS (
    SELECT d."segment",
           COUNT(DISTINCT f."product_code") AS "unique_products_2021"
    FROM   "hardware_fact_sales_monthly" AS f
    JOIN   "hardware_dim_product"        AS d
           ON f."product_code" = d."product_code"
    WHERE  f."fiscal_year" = 2021
    GROUP BY d."segment"
)
SELECT  y20."segment",
        y20."unique_products_2020",
        ROUND(
              100.0 * (IFNULL(y21."unique_products_2021",0) - y20."unique_products_2020")
              / NULLIF(y20."unique_products_2020",0)
        ,2) AS "pct_increase_2020_to_2021"
FROM    yr20 AS y20
LEFT JOIN yr21 AS y21
       ON y20."segment" = y21."segment"
ORDER BY "pct_increase_2020_to_2021" DESC;