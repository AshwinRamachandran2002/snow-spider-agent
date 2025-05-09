-- Top 3 counties (pop > 50 000) with highest COVID‑19 case‑fatality rate on 2020‑08‑27
WITH covid AS (
  SELECT
    LPAD(county_fips_code, 5, '0')             AS geo_id,
    county_name,
    state,
    SUM(confirmed_cases)                       AS cases,
    SUM(deaths)                                AS deaths
  FROM `bigquery-public-data.covid19_usafacts.summary`
  WHERE date = '2020-08-27'
    AND county_fips_code <> '00000'            -- exclude statewide “unallocated”
  GROUP BY geo_id, county_name, state
),
acs AS (
  SELECT
    geo_id,
    total_pop,
    median_age
  FROM `bigquery-public-data.census_bureau_acs.county_2020_5yr`
  WHERE total_pop > 50000                      -- only counties with pop > 50 000
)
SELECT
  c.county_name                           AS county,
  c.state                                  AS state,
  a.median_age,
  a.total_pop,
  ROUND(c.cases  * 1e5 / a.total_pop, 2)  AS cases_per_100k,
  ROUND(c.deaths * 1e5 / a.total_pop, 2)  AS deaths_per_100k,
  ROUND(c.deaths * 100.0 / NULLIF(c.cases,0), 2) AS case_fatality_rate_pct
FROM covid c
JOIN acs a USING (geo_id)
WHERE c.cases > 0
ORDER BY case_fatality_rate_pct DESC
LIMIT 3;