SELECT 
  '52003' AS "Zip_Code",
  TO_CHAR(s."date", 'YYYY-MM') AS "Month",
  ROUND(SUM(s."sale_dollars") / p."population_21_plus", 4) AS "Per_Capita_Sales"
FROM IOWA_LIQUOR_SALES_PLUS.IOWA_LIQUOR_SALES.SALES s
JOIN (
    SELECT "zipcode", SUM("population") AS "population_21_plus"
    FROM IOWA_LIQUOR_SALES_PLUS.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010
    WHERE "minimum_age" >= 21 AND "zipcode" = '52003'
    GROUP BY "zipcode"
) p ON REPLACE(s."zip_code", '.0', '') = p."zipcode"
WHERE REPLACE(s."zip_code", '.0', '') = '52003'
  AND s."category_name" ILIKE '%BOURBON%'
  AND s."date" BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY TO_CHAR(s."date", 'YYYY-MM'), p."population_21_plus"
ORDER BY "Month";