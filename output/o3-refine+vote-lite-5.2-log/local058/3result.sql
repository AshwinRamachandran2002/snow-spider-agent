WITH seg_year_counts AS (
    SELECT  dp.segment,
            fs.fiscal_year,
            COUNT(DISTINCT fs.product_code) AS unique_products
    FROM    hardware_fact_sales_monthly AS fs
    JOIN    hardware_dim_product        AS dp
            ON fs.product_code = dp.product_code
    WHERE   fs.fiscal_year IN (2020, 2021)
    GROUP BY dp.segment, fs.fiscal_year
),
seg_stats AS (
    SELECT  segment,
            SUM(CASE WHEN fiscal_year = 2020 THEN unique_products END) AS cnt_2020,
            SUM(CASE WHEN fiscal_year = 2021 THEN unique_products END) AS cnt_2021
    FROM    seg_year_counts
    GROUP BY segment
),
pct_change AS (
    SELECT  segment,
            cnt_2020,
            COALESCE(cnt_2021, 0)                                   AS cnt_2021,
            CASE
                WHEN cnt_2020 > 0
                THEN ((COALESCE(cnt_2021, 0) - cnt_2020) * 100.0) / cnt_2020
            END                                                    AS pct_increase
    FROM    seg_stats
)
SELECT  segment,
        cnt_2020 AS unique_product_count_2020
FROM    pct_change
WHERE   cnt_2020 IS NOT NULL
ORDER BY pct_increase DESC,
         segment;