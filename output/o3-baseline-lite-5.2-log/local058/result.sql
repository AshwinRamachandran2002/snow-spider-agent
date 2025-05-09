WITH prod_2020 AS (
    SELECT 
        dp.segment,
        COUNT(DISTINCT fs.product_code) AS prod_cnt_2020
    FROM hardware_fact_sales_monthly AS fs
    JOIN hardware_dim_product       AS dp
          ON fs.product_code = dp.product_code
    WHERE fs.fiscal_year = 2020
    GROUP BY dp.segment
),
prod_2021 AS (
    SELECT 
        dp.segment,
        COUNT(DISTINCT fs.product_code) AS prod_cnt_2021
    FROM hardware_fact_sales_monthly AS fs
    JOIN hardware_dim_product       AS dp
          ON fs.product_code = dp.product_code
    WHERE fs.fiscal_year = 2021
    GROUP BY dp.segment
),
combined AS (
    SELECT 
        p20.segment,
        p20.prod_cnt_2020,
        COALESCE(p21.prod_cnt_2021, 0) AS prod_cnt_2021,
        CASE 
            WHEN p20.prod_cnt_2020 = 0 THEN NULL
            ELSE (COALESCE(p21.prod_cnt_2021, 0) - p20.prod_cnt_2020) * 100.0 / p20.prod_cnt_2020
        END AS pct_increase
    FROM prod_2020 p20
    LEFT JOIN prod_2021 p21
           ON p20.segment = p21.segment
)
SELECT 
    segment,
    prod_cnt_2020 AS unique_product_count_2020
FROM combined
ORDER BY pct_increase DESC;