-- Top three ≥50k–population counties with highest COVID‑19 case–fatality rate
-- (CFR) on 27‑Aug‑2020, using 2020 ACS 5‑year county demographics
WITH
  covid AS (
    SELECT
      county_fips_code            AS fips,
      county_name                 AS county,
      state,
      CAST(confirmed_cases AS FLOAT64) AS cases,
      CAST(deaths          AS FLOAT64) AS deaths
    FROM `bigquery-public-data.covid19_usafacts.summary`
    WHERE date = '2020-08-27'
      -- keep only regular FIPS codes (skip statewide/unallocated “00000” rows)
      AND REGEXP_CONTAINS(county_fips_code, r'^\d{5}$')
  ),
  demo AS (
    SELECT
      geo_id                      AS fips,
      CAST(total_pop  AS FLOAT64) AS total_pop,
      CAST(median_age AS FLOAT64) AS median_age
    FROM `bigquery-public-data.census_bureau_acs.county_2020_5yr`
  )
SELECT
  c.county,
  c.state,
  d.median_age,
  d.total_pop,
  ROUND(c.cases  / d.total_pop * 100000, 2) AS cases_per_100k,
  ROUND(c.deaths / d.total_pop * 100000, 2) AS deaths_per_100k,
  ROUND(c.deaths / c.cases      *     100, 2) AS case_fatality_rate_percent
FROM covid c
JOIN demo d USING (fips)
WHERE d.total_pop >= 50000          -- only counties with ≥50 000 residents
  AND c.cases > 0                   -- avoid division by zero
ORDER BY case_fatality_rate_percent DESC
LIMIT 3;