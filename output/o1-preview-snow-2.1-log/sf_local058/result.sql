WITH
unique_products_2020 AS (
  SELECT hdp."segment", COUNT(DISTINCT hdp."product_code") AS "unique_product_count_2020"
  FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_DIM_PRODUCT" hdp
  INNER JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_FACT_SALES_MONTHLY" hfsm
    ON hdp."product_code" = hfsm."product_code"
  WHERE hfsm."fiscal_year" = 2020
  GROUP BY hdp."segment"
),
unique_products_2021 AS (
  SELECT hdp."segment", COUNT(DISTINCT hdp."product_code") AS "unique_product_count_2021"
  FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_DIM_PRODUCT" hdp
  INNER JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_FACT_SALES_MONTHLY" hfsm
    ON hdp."product_code" = hfsm."product_code"
  WHERE hfsm."fiscal_year" = 2021
  GROUP BY hdp."segment"
),
percentage_increase AS (
  SELECT
    u20."segment",
    u20."unique_product_count_2020",
    ROUND(((u21."unique_product_count_2021" - u20."unique_product_count_2020") / NULLIF(u20."unique_product_count_2020", 0)) * 100, 4) AS "percentage_increase"
  FROM unique_products_2020 u20
  JOIN unique_products_2021 u21 ON u20."segment" = u21."segment"
)
SELECT "segment", "unique_product_count_2020"
FROM percentage_increase
ORDER BY "percentage_increase" DESC NULLS LAST;