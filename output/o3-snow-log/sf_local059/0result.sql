WITH sales_2021 AS ( 
    SELECT 
        p."division" AS "division",
        s."product_code" AS "product_code",
        SUM(s."sold_quantity") AS "total_qty"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY s
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT p
      ON s."product_code" = p."product_code"
    WHERE TO_DATE(s."date", 'YYYY-MM-DD') BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY p."division", s."product_code"
), ranked_products AS (
    SELECT
        "division",
        "product_code",
        "total_qty",
        ROW_NUMBER() OVER (PARTITION BY "division" ORDER BY "total_qty" DESC NULLS LAST) AS "rn"
    FROM sales_2021
), top_three AS (
    SELECT
        "division",
        "product_code",
        "total_qty"
    FROM ranked_products
    WHERE "rn" <= 3
)
SELECT
    "division",
    AVG("total_qty") AS "avg_quantity_sold"
FROM top_three
GROUP BY "division"
ORDER BY "division";