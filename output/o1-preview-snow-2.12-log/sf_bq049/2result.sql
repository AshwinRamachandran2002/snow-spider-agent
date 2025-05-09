WITH population AS (
  SELECT SUM("population") AS "population_21_plus"
  FROM "IOWA_LIQUOR_SALES_PLUS"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010"
  WHERE "zipcode" = '52001' AND "minimum_age" >= 21
)
SELECT 
  TO_CHAR(DATE_TRUNC('month', s."date"), 'Mon-YYYY') AS "Month",
  ROUND(SUM(s."sale_dollars") / population."population_21_plus", 4) AS "Per_Capita_Bourbon_Whiskey_Sales"
FROM "IOWA_LIQUOR_SALES_PLUS"."IOWA_LIQUOR_SALES"."SALES" s, population
WHERE s."zip_code" = '52001'
  AND s."date" BETWEEN '2022-01-01' AND '2022-12-31'
  AND s."item_description" ILIKE '%bourbon%'
GROUP BY "Month", population."population_21_plus"
ORDER BY "Month";