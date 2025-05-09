SELECT
  s."county_name" AS "Name",
  s."state" AS "State",
  c."median_age" AS "Median Age",
  c."total_pop" AS "Total Population",
  ROUND((CAST(s."confirmed_cases" AS FLOAT) / c."total_pop") * 100000, 4) AS "Confirmed COVID-19 Cases per 100,000",
  ROUND((CAST(s."deaths" AS FLOAT) / c."total_pop") * 100000, 4) AS "Deaths per 100,000",
  ROUND((CAST(s."deaths" AS FLOAT) / NULLIF(CAST(s."confirmed_cases" AS FLOAT), 0)) * 100, 4) AS "Case Fatality Rate Percentage"
FROM
  COVID19_USA.CENSUS_BUREAU_ACS."COUNTY_2020_5YR" c
JOIN
  COVID19_USA.COVID19_USAFACTS."SUMMARY" s
ON
  RIGHT(c."geo_id", 5) = LPAD(s."county_fips_code", 5, '0')
WHERE
  s."date" = '2020-08-27'
  AND c."total_pop" > 50000
  AND s."confirmed_cases" > 0
ORDER BY
  "Case Fatality Rate Percentage" DESC NULLS LAST
LIMIT 3;