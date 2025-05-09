WITH yearly_counts AS (           -- count distinct products per segment & year
    SELECT dp.segment,
           fm.fiscal_year                 AS yr,
           COUNT(DISTINCT fm.product_code) AS cnt
    FROM hardware_fact_sales_monthly AS fm
    JOIN hardware_dim_product       AS dp
      ON dp.product_code = fm.product_code
    WHERE fm.fiscal_year IN (2020, 2021)
    GROUP BY dp.segment, fm.fiscal_year
),
pivot AS (                         -- turn the two years into separate columns
    SELECT segment,
           MAX(CASE WHEN yr = 2020 THEN cnt END) AS cnt20,
           MAX(CASE WHEN yr = 2021 THEN cnt END) AS cnt21
    FROM yearly_counts
    GROUP BY segment
),
pct_change AS (                    -- calculate % increase from 2020 to 2021
    SELECT segment,
           cnt20 AS unique_products_2020,
           (cnt21 - cnt20) * 1.0 / NULLIF(cnt20, 0) AS pct_increase
    FROM pivot
    WHERE cnt20 IS NOT NULL              -- ensure 2020 data exists
)
SELECT segment,
       unique_products_2020
FROM pct_change
ORDER BY pct_increase DESC;