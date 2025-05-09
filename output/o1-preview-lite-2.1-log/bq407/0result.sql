SELECT
  c.county_name AS County_Name,
  c.state AS State,
  census.median_age AS Median_Age,
  CAST(census.total_pop AS INT64) AS Total_Population,
  ROUND((c.confirmed_cases / census.total_pop) * 100000, 4) AS Confirmed_Cases_per_100k,
  ROUND((d.deaths / census.total_pop) * 100000, 4) AS Deaths_per_100k,
  ROUND(SAFE_DIVIDE(d.deaths, c.confirmed_cases) * 100, 4) AS Case_Fatality_Rate
FROM
  (
    SELECT
      county_fips_code,
      county_name,
      state,
      SAFE_CAST(`_2020_08_27` AS NUMERIC) AS confirmed_cases
    FROM
      `bigquery-public-data.covid19_usafacts.confirmed_cases`
    WHERE
      county_fips_code != '00000'  -- Exclude Statewide Unallocated
  ) AS c
JOIN
  (
    SELECT
      county_fips_code,
      SAFE_CAST(`_2020_08_27` AS NUMERIC) AS deaths
    FROM
      `bigquery-public-data.covid19_usafacts.deaths`
    WHERE
      county_fips_code != '00000'  -- Exclude Statewide Unallocated
  ) AS d
ON
  c.county_fips_code = d.county_fips_code
JOIN
  (
    SELECT
      LPAD(CAST(geo_id AS STRING), 5, '0') AS county_fips_code,
      total_pop,
      median_age
    FROM
      `bigquery-public-data.census_bureau_acs.county_2020_5yr`
    WHERE
      total_pop > 50000  -- Population over 50,000
  ) AS census
ON
  c.county_fips_code = census.county_fips_code
WHERE
  c.confirmed_cases > 0  -- Ensure there are confirmed cases to avoid division by zero
ORDER BY
  Case_Fatality_Rate DESC
LIMIT
  3;