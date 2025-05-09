SELECT
  covid.county_name AS County_Name,
  covid.state AS State,
  c.median_age AS Median_Age,
  c.total_pop AS Total_Population,
  (covid.confirmed_cases / c.total_pop) * 100000 AS Confirmed_Cases_per_100k,
  (covid.deaths / c.total_pop) * 100000 AS Deaths_per_100k,
  (covid.deaths / NULLIF(covid.confirmed_cases, 0)) * 100 AS Case_Fatality_Rate
FROM
  `bigquery-public-data.census_bureau_acs.county_2020_5yr` AS c
JOIN
  `bigquery-public-data.covid19_usafacts.summary` AS covid
ON
  LPAD(CAST(c.geo_id AS STRING), 5, '0') = covid.county_fips_code
WHERE
  covid.date = '2020-08-27'
  AND c.total_pop > 50000
  AND covid.confirmed_cases > 0
ORDER BY
  Case_Fatality_Rate DESC
LIMIT 3;