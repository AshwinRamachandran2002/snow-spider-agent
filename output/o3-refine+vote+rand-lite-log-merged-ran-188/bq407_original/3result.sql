-- Top three ≥50k‑population counties (2020 ACS 5‑yr) with the highest
-- COVID‑19 case‑fatality rates as of 27 Aug 2020
WITH pop AS (
  SELECT
    LPAD(CAST(geo_id AS STRING), 5, '0') AS fips,
    total_pop,
    median_age
  FROM `bigquery-public-data.census_bureau_acs.county_2020_5yr`
  WHERE total_pop > 50000
),
covid AS (
  SELECT
    county_fips_code AS fips,
    county_name,
    state,
    CAST(confirmed_cases AS FLOAT64) AS confirmed_cases,
    CAST(deaths AS FLOAT64)          AS deaths
  FROM `bigquery-public-data.covid19_usafacts.summary`
  WHERE date = '2020-08-27'
),
merged AS (
  SELECT
    c.county_name,
    c.state,
    p.median_age,
    p.total_pop,
    c.confirmed_cases,
    c.deaths,
    100000 * c.confirmed_cases / p.total_pop AS cases_per_100k,
    100000 * c.deaths         / p.total_pop AS deaths_per_100k,
    100      * c.deaths / NULLIF(c.confirmed_cases,0) AS cfr_pct
  FROM covid c
  JOIN pop  p USING (fips)
  WHERE c.confirmed_cases > 0
)
SELECT
  county_name,
  state,
  ROUND(median_age,2)                 AS median_age,
  total_pop,
  ROUND(cases_per_100k ,2)            AS cases_per_100k,
  ROUND(deaths_per_100k,2)            AS deaths_per_100k,
  ROUND(cfr_pct,2)                    AS case_fatality_rate_percent
FROM merged
ORDER BY cfr_pct DESC, county_name
LIMIT 3;