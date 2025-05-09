WITH counts AS (
  SELECT
    hdp."segment" AS Segment,
    COUNT(DISTINCT CASE WHEN hfs."fiscal_year" = 2020 THEN hfs."product_code" END) AS Unique_Product_Count_2020,
    COUNT(DISTINCT CASE WHEN hfs."fiscal_year" = 2021 THEN hfs."product_code" END) AS Unique_Product_Count_2021,
    CASE
      WHEN COUNT(DISTINCT CASE WHEN hfs."fiscal_year" = 2020 THEN hfs."product_code" END) = 0 THEN NULL
      ELSE ROUND(((COUNT(DISTINCT CASE WHEN hfs."fiscal_year" = 2021 THEN hfs."product_code" END) - COUNT(DISTINCT CASE WHEN hfs."fiscal_year" = 2020 THEN hfs."product_code" END)) * 100.0 / COUNT(DISTINCT CASE WHEN hfs."fiscal_year" = 2020 THEN hfs."product_code" END)), 4)
    END AS percentage_increase
  FROM "hardware_fact_sales_monthly" AS hfs
  JOIN "hardware_dim_product" AS hdp
    ON hfs."product_code" = hdp."product_code"
  WHERE hfs."fiscal_year" IN (2020, 2021)
  GROUP BY hdp."segment"
)
SELECT
  Segment,
  Unique_Product_Count_2020
FROM counts
ORDER BY percentage_increase DESC;