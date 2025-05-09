SELECT 
    b."state_name",
    ROUND(SUM(a."employed_wholesale_trade" * 0.38), 4) AS "Vulnerable_Wholesale_Trade_Workers",
    ROUND(SUM(a."employed_manufacturing" * 0.41), 4) AS "Vulnerable_Manufacturing_Workers",
    ROUND(SUM(a."employed_wholesale_trade" * 0.38 + a."employed_manufacturing" * 0.41), 4) AS "Total_Vulnerable_Workers"
FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR" a
JOIN "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES" b
  ON a."geo_id" = b."zip_code"
JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR" c
  ON a."geo_id" = c."geo_id"
JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR" d
  ON a."geo_id" = d."geo_id"
WHERE (d."median_income" - c."median_income") < 0
GROUP BY b."state_name"
ORDER BY "Total_Vulnerable_Workers" DESC NULLS LAST;