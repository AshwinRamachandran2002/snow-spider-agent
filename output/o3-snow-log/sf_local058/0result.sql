WITH product_sales AS (
    SELECT 
        p."segment",
        f."product_code",
        f."fiscal_year"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY AS f
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT        AS p
          ON f."product_code" = p."product_code"
    WHERE f."fiscal_year" IN (2020, 2021)
), 
yearly_unique AS (
    SELECT
        "segment",
        "fiscal_year",
        COUNT(DISTINCT "product_code") AS "unique_cnt"
    FROM product_sales
    GROUP BY "segment", "fiscal_year"
), 
segment_growth AS (
    SELECT
        y20."segment",
        y20."unique_cnt"                     AS "cnt_2020",
        COALESCE(y21."unique_cnt", 0)        AS "cnt_2021",
        CASE
            WHEN y20."unique_cnt" = 0 THEN NULL
            ELSE (COALESCE(y21."unique_cnt", 0) - y20."unique_cnt") 
                 * 100.0 / y20."unique_cnt"
        END                                   AS "pct_increase"
    FROM yearly_unique y20
    LEFT JOIN yearly_unique y21
           ON y20."segment" = y21."segment" 
          AND y21."fiscal_year" = 2021
    WHERE y20."fiscal_year" = 2020
)

SELECT
    "segment",
    "cnt_2020"   AS "unique_product_count_2020"
FROM segment_growth
ORDER BY "pct_increase" DESC NULLS LAST;