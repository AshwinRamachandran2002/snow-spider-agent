WITH sales_20_21 AS (      -- products that had any sales in FY 2020 or 2021
    SELECT DISTINCT 
           "product_code",
           "fiscal_year"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY
    WHERE "fiscal_year" IN (2020, 2021)
),  
prod_seg AS (              -- attach the product segment
    SELECT 
           p."product_code",
           p."segment"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT p
),  
seg_year_cnt AS (          -- unique-product count per segment & fiscal-year
    SELECT 
           ps."segment",
           s."fiscal_year",
           COUNT(DISTINCT s."product_code") AS unique_products
    FROM sales_20_21 s
    JOIN prod_seg ps 
          ON s."product_code" = ps."product_code"
    GROUP BY ps."segment", s."fiscal_year"
),  
seg_cnt_pivot AS (         -- pivot to get 2020 and 2021 counts side by side
    SELECT 
           "segment",
           MAX(CASE WHEN "fiscal_year" = 2020 THEN unique_products END) AS products_2020,
           MAX(CASE WHEN "fiscal_year" = 2021 THEN unique_products END) AS products_2021
    FROM seg_year_cnt
    GROUP BY "segment"
),  
pct_calc AS (              -- compute % increase
    SELECT
           "segment",
           products_2020,
           products_2021,
           ROUND( (products_2021 - products_2020) * 100.0 / NULLIF(products_2020, 0), 2) 
           AS pct_increase
    FROM seg_cnt_pivot
    WHERE products_2020 IS NOT NULL
          AND products_2021 IS NOT NULL
          AND products_2020 > 0
)
SELECT 
       "segment",
       products_2020            -- unique product count for 2020
FROM pct_calc
ORDER BY pct_increase DESC NULLS LAST;   -- highest % increase on top