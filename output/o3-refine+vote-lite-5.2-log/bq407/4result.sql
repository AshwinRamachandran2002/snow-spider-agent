WITH pop AS (
  SELECT
    LPAD(CAST(geo_id AS STRING), 5, '0')              AS county_fips_code,
    CAST(total_pop AS FLOAT64)                         AS total_pop,
    CAST(median_age AS FLOAT64)                        AS median_age
  FROM `bigquery-public-data.census_bureau_acs.county_2020_5yr`
  WHERE total_pop > 50000
),
covid AS (
  SELECT
    county_fips_code,
    county_name,
    state,
    CAST(confirmed_cases AS FLOAT64)                   AS cases,
    CAST(deaths          AS FLOAT64)                   AS deaths
  FROM `bigquery-public-data.covid19_usafacts.summary`
  WHERE date = '2020-08-27'
    AND county_fips_code != '00000'                    -- exclude statewide/unallocated rows
)
SELECT
  c.county_name                                        AS county,
  c.state,
  p.median_age,
  p.total_pop,
  ROUND(c.cases  / p.total_pop * 100000, 2)            AS cases_per_100k,
  ROUND(c.deaths / p.total_pop * 100000, 2)            AS deaths_per_100k,
  ROUND(c.deaths / c.cases * 100, 2)                   AS case_fatality_rate_percent
FROM covid c
JOIN pop  p USING (county_fips_code)
WHERE c.cases > 0                                       -- guard against division by zero
ORDER BY case_fatality_rate_percent DESC
LIMIT 3;