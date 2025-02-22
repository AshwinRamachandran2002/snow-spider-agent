-- Task: Provide a list of hardware product segments along with their unique product counts for 2020
SELECT hdp."segment", COUNT(DISTINCT hdp."product_code") AS "unique_product_count_2020"
FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_DIM_PRODUCT" hdp
INNER JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_FACT_SALES_MONTHLY" hfsm
  ON hdp."product_code" = hfsm."product_code"
WHERE hfsm."fiscal_year" = 2020
GROUP BY hdp."segment";