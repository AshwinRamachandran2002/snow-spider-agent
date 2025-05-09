SELECT 
  s."county_name", 
  s."state", 
  c."median_age", 
  c."total_pop", 
  ROUND((s."confirmed_cases" / c."total_pop") * 100000, 4) AS "Confirmed COVID-19 Cases per 100,000", 
  ROUND((s."deaths" / c."total_pop") * 100000, 4) AS "Deaths per 100,000", 
  ROUND((s."deaths" / NULLIF(s."confirmed_cases", 0)) * 100, 4) AS "Case Fatality Rate Percentage"
FROM 
  "COVID19_USA"."CENSUS_BUREAU_ACS"."COUNTY_2020_5YR" AS c
JOIN 
  "COVID19_USA"."COVID19_USAFACTS"."SUMMARY" AS s
ON 
  c."geo_id" = s."county_fips_code"
WHERE 
  c."total_pop" > 50000 
  AND s."date" = '2020-08-27'
ORDER BY 
  "Case Fatality Rate Percentage" DESC NULLS LAST
LIMIT 3;