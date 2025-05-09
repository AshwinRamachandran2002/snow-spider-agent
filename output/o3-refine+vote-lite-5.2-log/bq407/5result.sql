WITH
-- 1. 2020 ACS county‑level demographics
acs AS (
  SELECT
    geo_id                              AS fips,
    CAST(total_pop AS FLOAT64)          AS total_pop,
    CAST(median_age AS FLOAT64)         AS median_age
  FROM `bigquery-public-data.census_bureau_acs.county_2020_5yr`
  WHERE
    -- keep valid 5–digit county FIPS and population > 50,000
    LENGTH(geo_id)=5
    AND CAST(total_pop AS FLOAT64) > 50000
),

-- 2. COVID‑19 cumulative counts on 2020‑08‑27
covid AS (
  SELECT
    county_fips_code                    AS fips,
    county_name,
    state,
    CAST(confirmed_cases AS FLOAT64)    AS cases,
    CAST(deaths AS FLOAT64)             AS deaths
  FROM `bigquery-public-data.covid19_usafacts.summary`
  WHERE date = DATE '2020-08-27'
    AND county_fips_code NOT LIKE '%00000'    -- drop state‑level rows
),

-- 3. Combine and compute per‑capita metrics & CFR
combined AS (
  SELECT
    c.county_name,
    c.state,
    a.median_age,
    a.total_pop,
    c.cases,
    c.deaths,
    (c.cases / a.total_pop)  * 100000 AS cases_per_100k,
    (c.deaths / a.total_pop) * 100000 AS deaths_per_100k,
    (c.deaths / c.cases)     * 100     AS case_fatality_rate
  FROM covid c
  JOIN acs  a USING (fips)
  WHERE c.cases > 0                -- avoid division by zero
)

-- 4. Top 3 counties by highest CFR
SELECT
  county_name      AS county,
  state,
  ROUND(median_age,2)                 AS median_age,
  ROUND(total_pop)                    AS total_population,
  ROUND(cases_per_100k ,2)            AS cases_per_100k,
  ROUND(deaths_per_100k,2)            AS deaths_per_100k,
  ROUND(case_fatality_rate ,2)        AS case_fatality_rate_percent
FROM combined
ORDER BY case_fatality_rate DESC, county_name
LIMIT 3;