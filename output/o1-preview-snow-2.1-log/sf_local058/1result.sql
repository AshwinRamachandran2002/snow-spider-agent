WITH
-- Unique product counts per segment for 2020
product_counts_2020 AS (
  SELECT
    hdp."segment",
    COUNT(DISTINCT hfsm."product_code") AS "unique_product_count_2020"
  FROM
    "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_DIM_PRODUCT" hdp
    JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_FACT_SALES_MONTHLY" hfsm
      ON hdp."product_code" = hfsm."product_code"
  WHERE
    hfsm."fiscal_year" = 2020
  GROUP BY
    hdp."segment"
),
-- Unique product counts per segment for 2021
product_counts_2021 AS (
  SELECT
    hdp."segment",
    COUNT(DISTINCT hfsm."product_code") AS "unique_product_count_2021"
  FROM
    "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_DIM_PRODUCT" hdp
    JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."HARDWARE_FACT_SALES_MONTHLY" hfsm
      ON hdp."product_code" = hfsm."product_code"
  WHERE
    hfsm."fiscal_year" = 2021
  GROUP BY
    hdp."segment"
),
-- Combine counts and calculate percentage increase
segment_counts AS (
  SELECT
    COALESCE(p2020."segment", p2021."segment") AS "segment",
    COALESCE(p2020."unique_product_count_2020", 0) AS "unique_product_count_2020",
    COALESCE(p2021."unique_product_count_2021", 0) AS "unique_product_count_2021",
    CASE
      WHEN COALESCE(p2020."unique_product_count_2020", 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE(p2021."unique_product_count_2021", 0) - p2020."unique_product_count_2020") / p2020."unique_product_count_2020"::FLOAT) * 100.0, 4)
    END AS "percentage_increase"
  FROM
    product_counts_2020 p2020
    FULL OUTER JOIN product_counts_2021 p2021
      ON p2020."segment" = p2021."segment"
)
-- Final selection and ordering by highest percentage increase
SELECT
  "segment",
  "unique_product_count_2020"
FROM
  segment_counts
ORDER BY
  "percentage_increase" DESC NULLS LAST
;