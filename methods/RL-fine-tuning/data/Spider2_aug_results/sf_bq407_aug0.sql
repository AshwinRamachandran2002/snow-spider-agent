-- Task: Find the top three counties with total populations over 50,000, using the 2020 5-year census data, that had the highest COVID-19 case fatality rates on August 27, 2020. Only include counties with at least one confirmed COVID-19 case. For these counties, provide the county name, state, median age, total population, the number of confirmed COVID-19 cases per 100,000 people (calculated as (confirmed cases / total population) * 100,000), the number of deaths per 100,000 people (calculated as (deaths / total population) * 100,000), and the case fatality rate percentage (calculated as (deaths / confirmed cases) * 100). Round these calculated values to four decimal places. Order the results by the case fatality rate percentage in descending order, and return only the top three counties.
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