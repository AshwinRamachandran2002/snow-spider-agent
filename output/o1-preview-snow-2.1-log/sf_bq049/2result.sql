SELECT
    '52001' AS "Zip_Code",
    TO_CHAR(DATE_TRUNC('month', s."date"), 'Mon-YYYY') AS "Month",
    ROUND(SUM(s."sale_dollars") / p."population_21_plus", 4) AS "Per_Capita_Sales"
FROM "IOWA_LIQUOR_SALES_PLUS"."IOWA_LIQUOR_SALES"."SALES" s
JOIN (
    SELECT "zipcode", SUM("population") AS "population_21_plus"
    FROM "IOWA_LIQUOR_SALES_PLUS"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010"
    WHERE "minimum_age" >= 21 AND "zipcode" = '52001'
    GROUP BY "zipcode"
) p ON TO_NUMBER(s."zip_code") = TO_NUMBER(p."zipcode")
WHERE s."county" = 'DUBUQUE'
  AND s."category_name" ILIKE '%Bourbon%'
  AND s."date" BETWEEN '2022-01-01' AND '2022-12-31'
  AND (s."zip_code" = '52001' OR s."zip_code" = '52001.0')
GROUP BY TO_CHAR(DATE_TRUNC('month', s."date"), 'Mon-YYYY'), p."population_21_plus"
ORDER BY TO_DATE(TO_CHAR(DATE_TRUNC('month', s."date"), 'Mon-YYYY'), 'Mon-YYYY')
LIMIT 12;