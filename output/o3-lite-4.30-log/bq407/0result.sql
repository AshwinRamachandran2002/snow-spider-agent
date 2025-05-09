WITH pop AS (
  SELECT
    LPAD(CAST(geo_id AS STRING), 5, '0') AS fips,
    total_pop,
    median_age
  FROM `bigquery-public-data.census_bureau_acs.county_2020_5yr`
  WHERE total_pop >= 50000
),
cases AS (
  SELECT
    county_fips_code AS fips,
    county_name,
    state,
    `_2020_08_27` AS cases
  FROM `bigquery-public-data.covid19_usafacts.confirmed_cases`
),
deaths AS (
  SELECT
    county_fips_code AS fips,
    `_2020_08_27` AS deaths
  FROM `bigquery-public-data.covid19_usafacts.deaths`
)
SELECT
  c.county_name                                   AS county,
  c.state                                         AS state,
  p.median_age,
  p.total_pop                                     AS population,
  ROUND(SAFE_DIVIDE(c.cases,  p.total_pop) * 100000, 4) AS cases_per_100k,
  ROUND(SAFE_DIVIDE(d.deaths, p.total_pop) * 100000, 4) AS deaths_per_100k,
  ROUND(SAFE_DIVIDE(d.deaths, c.cases) * 100, 4)        AS case_fatality_rate_pct
FROM pop p
JOIN cases  c ON p.fips = c.fips
JOIN deaths d ON p.fips = d.fips
WHERE c.cases > 0
ORDER BY case_fatality_rate_pct DESC, county, state
LIMIT 3;