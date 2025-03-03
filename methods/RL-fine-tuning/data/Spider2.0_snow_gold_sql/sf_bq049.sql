WITH total_sales_per_zip AS (
  SELECT "zip_code",
         SUM("sale_dollars") AS "total_sales",
         ROW_NUMBER() OVER (ORDER BY SUM("sale_dollars") DESC NULLS LAST) AS "rn"
  FROM "IOWA_LIQUOR_SALES_PLUS"."IOWA_LIQUOR_SALES"."SALES"
  WHERE "county" = 'DUBUQUE' AND
        "category_name" LIKE '%BOURBON%' AND
        "date" BETWEEN '2022-01-01' AND '2022-12-31'
  GROUP BY "zip_code"
),
third_zip AS (
  SELECT "zip_code"
  FROM total_sales_per_zip
  WHERE "rn" = 3
),
population_21_and_over AS (
  SELECT "zipcode", SUM("population") AS "population"
  FROM "IOWA_LIQUOR_SALES_PLUS"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010"
  WHERE "minimum_age" >= 21 AND
        "zipcode" = (SELECT "zip_code" FROM third_zip)
  GROUP BY "zipcode"
),
months AS (
  SELECT DATEADD(month, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2022-01-01') AS "month"
  FROM TABLE(GENERATOR(ROWCOUNT => 12))
),
monthly_sales AS (
  SELECT DATE_TRUNC('month', "date") AS "month", SUM("sale_dollars") AS "monthly_sales"
  FROM "IOWA_LIQUOR_SALES_PLUS"."IOWA_LIQUOR_SALES"."SALES"
  WHERE "county" = 'DUBUQUE' AND
        "zip_code" = (SELECT "zip_code" FROM third_zip) AND
        "category_name" LIKE '%BOURBON%' AND
        "date" BETWEEN '2022-01-01' AND '2022-12-31'
  GROUP BY DATE_TRUNC('month', "date")
),
monthly_data AS (
  SELECT months."month", COALESCE(monthly_sales."monthly_sales", 0) AS "monthly_sales"
  FROM months
  LEFT JOIN monthly_sales ON months."month" = monthly_sales."month"
),
result AS (
  SELECT TO_VARCHAR(monthly_data."month", 'Mon-YYYY') AS "Month",
         ROUND(monthly_data."monthly_sales" / population_21_and_over."population", 4) AS "Per_Capita_Bourbon_Whiskey_Sales"
  FROM monthly_data
  CROSS JOIN population_21_and_over
)
SELECT "Month", "Per_Capita_Bourbon_Whiskey_Sales"
FROM result
ORDER BY TO_DATE("Month", 'Mon-YYYY');