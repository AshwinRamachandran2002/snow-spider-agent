WITH sales_2020 AS (
    SELECT hdp.segment,
           COUNT(DISTINCT hfs.product_code) AS cnt20
    FROM hardware_fact_sales_monthly AS hfs
    JOIN hardware_dim_product        AS hdp
      ON hfs.product_code = hdp.product_code
    WHERE hfs.fiscal_year = 2020
    GROUP BY hdp.segment
),
sales_2021 AS (
    SELECT hdp.segment,
           COUNT(DISTINCT hfs.product_code) AS cnt21
    FROM hardware_fact_sales_monthly AS hfs
    JOIN hardware_dim_product        AS hdp
      ON hfs.product_code = hdp.product_code
    WHERE hfs.fiscal_year = 2021
    GROUP BY hdp.segment
)
SELECT  s20.segment,
        s20.cnt20                          AS unique_products_2020,
        ROUND(
            (COALESCE(s21.cnt21,0) - s20.cnt20) * 100.0 /
            NULLIF(s20.cnt20,0), 2
        )                                  AS pct_increase_20_to_21
FROM    sales_2020 s20
LEFT JOIN sales_2021 s21
       ON s20.segment = s21.segment
ORDER BY pct_increase_20_to_21 DESC;