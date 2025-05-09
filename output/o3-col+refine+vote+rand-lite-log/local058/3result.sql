WITH yearly_counts AS (
    SELECT hdp."segment",
           hfsm."fiscal_year",
           COUNT(DISTINCT hfsm."product_code") AS unique_products
    FROM   "hardware_fact_sales_monthly" AS hfsm
    JOIN   "hardware_dim_product"        AS hdp
           ON hfsm."product_code" = hdp."product_code"
    WHERE  hfsm."fiscal_year" IN (2020, 2021)
    GROUP  BY hdp."segment", hfsm."fiscal_year"
),
pivoted AS (
    SELECT  yc20."segment",
            yc20."unique_products" AS unique_products_2020,
            COALESCE(yc21."unique_products", 0) AS unique_products_2021
    FROM    yearly_counts AS yc20
    LEFT JOIN yearly_counts AS yc21
           ON yc20."segment"      = yc21."segment"
          AND yc21."fiscal_year"  = 2021
    WHERE   yc20."fiscal_year"    = 2020
)
SELECT "segment",
       unique_products_2020
FROM   pivoted
ORDER  BY (1.0 * (unique_products_2021 - unique_products_2020) /
           NULLIF(unique_products_2020, 0)) DESC;