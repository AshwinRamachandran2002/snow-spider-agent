-- Task: For counties with populations over 50,000, using the 2020 5-year census data, that had confirmed COVID-19 cases on August 27, 2020, find the case fatality rates (number of deaths divided by number of confirmed cases) as percentages. Provide the name, state, median age, total population, number of confirmed COVID-19 cases, number of deaths, and case fatality rate percentage (limit to 100 results).
SELECT
  s."county_name" AS "Name",
  s."state" AS "State",
  c."median_age" AS "Median Age",
  c."total_pop" AS "Total Population",
  s."confirmed_cases" AS "Confirmed COVID-19 Cases",
  s."deaths" AS "Deaths",
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
LIMIT 100;