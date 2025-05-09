WITH county_demo AS (
  -- 2020 5‑year ACS county‑level demographics
  SELECT
    LPAD(CAST(geo_id AS STRING), 5, '0')           AS county_fips,
    total_pop                                       AS population,
    median_age
  FROM `bigquery-public-data.census_bureau_acs.county_2020_5yr`
),
covid_082720 AS (
  -- cumulative COVID‑19 counts as of 27‑Aug‑2020
  SELECT
    county_fips_code                                AS county_fips,
    county_name,
    state,
    SUM(confirmed_cases)                            AS cases,
    SUM(deaths)                                     AS deaths
  FROM `bigquery-public-data.covid19_usafacts.summary`
  WHERE date = DATE '2020-08-27'
  GROUP BY county_fips, county_name, state
),
combined AS (
  -- join the two sources and compute rates
  SELECT
    c.county_name,
    c.state,
    d.median_age,
    d.population,
    c.cases,
    c.deaths,
    100000 * c.cases  / d.population               AS cases_per_100k,
    100000 * c.deaths / d.population               AS deaths_per_100k,
    100 * SAFE_DIVIDE(c.deaths, c.cases)           AS case_fatality_rate
  FROM covid_082720 AS c
  JOIN county_demo  AS d USING (county_fips)
  WHERE d.population > 50000        -- only counties with >50 000 residents
        AND c.cases > 0             -- avoid division by zero
)
SELECT
  county_name                       AS county,
  state,
  ROUND(median_age, 1)              AS median_age,
  CAST(population AS INT64)         AS total_population,
  ROUND(cases_per_100k, 1)          AS cases_per_100k,
  ROUND(deaths_per_100k, 1)         AS deaths_per_100k,
  ROUND(case_fatality_rate, 2)      AS case_fatality_rate_percent
FROM combined
ORDER BY case_fatality_rate DESC
LIMIT 3;