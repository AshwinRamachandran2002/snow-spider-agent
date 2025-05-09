WITH total_sales_per_zip AS (
  SELECT TRIM(s."zip_code") AS "zip_code",
         SUM(s."sale_dollars") AS total_sales
  FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES."SALES" s
  WHERE s."county" ILIKE '%Dubuque%'
    AND s."category_name" ILIKE '%Bourbon%'
    AND s."date" >= '2022-01-01' AND s."date" < '2023-01-01'
    AND s."zip_code" IS NOT NULL
  GROUP BY TRIM(s."zip_code")
),
sales_ranking AS (
  SELECT "zip_code", total_sales,
         ROW_NUMBER() OVER (ORDER BY total_sales DESC NULLS LAST) AS sales_rank
  FROM total_sales_per_zip
),
third_zip AS (
  SELECT "zip_code"
  FROM sales_ranking
  WHERE sales_rank = 3
),
population_21_plus AS (
  SELECT TRIM("zipcode") AS "zip_code",
         SUM("population") AS population_21_plus
  FROM IOWA_LIQUOR_SALES_PLUS.CENSUS_BUREAU_USA."POPULATION_BY_ZIP_2010"
  WHERE "minimum_age" >= 21
    AND TRIM("zipcode") = (SELECT "zip_code" FROM third_zip)
  GROUP BY TRIM("zipcode")
),
monthly_sales AS (
  SELECT TO_CHAR(s."date", 'Mon-YYYY') AS "Month",
         SUM(s."sale_dollars") AS total_sales,
         TRIM(s."zip_code") AS "zip_code"
  FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES."SALES" s
  WHERE s."county" ILIKE '%Dubuque%'
    AND s."category_name" ILIKE '%Bourbon%'
    AND TRIM(s."zip_code") = (SELECT "zip_code" FROM third_zip)
    AND s."date" >= '2022-01-01' AND s."date" < '2023-01-01'
  GROUP BY "Month", TRIM(s."zip_code")
)
SELECT m."Month", 
       ROUND(m.total_sales / p.population_21_plus, 4) AS "Per_Capita_Bourbon_Whiskey_Sales"
FROM monthly_sales m
JOIN population_21_plus p ON m."zip_code" = p."zip_code"
ORDER BY m."Month" NULLS LAST;