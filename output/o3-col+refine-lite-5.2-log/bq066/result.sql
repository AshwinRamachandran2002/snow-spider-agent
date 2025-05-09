-- Pearson correlation between county‑level poverty rate (previous‑year 5‑yr ACS)
-- and share of births with NO reported maternal morbidity
-- for U.S. counties, birth years 2016‑2018
WITH
/* ---------- poverty rates from prior‑year 5‑year ACS ---------- */
poverty_2015 AS (
  SELECT
    geo_id AS county_fips,
    SAFE_DIVIDE(poverty , pop_determined_poverty_status) AS pov_rate_2015
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  WHERE pop_determined_poverty_status > 0
),
poverty_2016 AS (
  SELECT
    geo_id AS county_fips,
    SAFE_DIVIDE(poverty , pop_determined_poverty_status) AS pov_rate_2016
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  WHERE pop_determined_poverty_status > 0
),
poverty_2017 AS (
  SELECT
    geo_id AS county_fips,
    SAFE_DIVIDE(poverty , pop_determined_poverty_status) AS pov_rate_2017
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
  WHERE pop_determined_poverty_status > 0
),
/* ---------- total births by county & year ---------- */
births_tot AS (
  SELECT
    EXTRACT(YEAR FROM Year)                AS birth_year,
    County_of_Residence_FIPS               AS county_fips,
    SUM(Births)                            AS births_tot
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
  WHERE EXTRACT(YEAR FROM Year) IN (2016,2017,2018)
  GROUP BY birth_year, county_fips
),
/* ---------- births with NO maternal morbidity reported ---------- */
births_no_morb AS (
  SELECT
    EXTRACT(YEAR FROM Year)                AS birth_year,
    County_of_Residence_FIPS               AS county_fips,
    SUM(Births)                            AS births_no_morb
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM Year) IN (2016,2017,2018)
    AND Maternal_Morbidity_Desc = 'None checked'
    AND Maternal_Morbidity_YN = 1
  GROUP BY birth_year, county_fips
),
/* ---------- assemble analysis tables for each year ---------- */
analytic_2016 AS (
  SELECT
    p.pov_rate_2015        AS poverty_rate,
    SAFE_DIVIDE(n.births_no_morb , t.births_tot) AS pct_no_morb
  FROM births_tot t
  JOIN births_no_morb n
    USING (birth_year, county_fips)
  JOIN poverty_2015 p
    ON p.county_fips = t.county_fips
  WHERE t.birth_year = 2016
    AND t.births_tot > 0
),
analytic_2017 AS (
  SELECT
    p.pov_rate_2016        AS poverty_rate,
    SAFE_DIVIDE(n.births_no_morb , t.births_tot) AS pct_no_morb
  FROM births_tot t
  JOIN births_no_morb n
    USING (birth_year, county_fips)
  JOIN poverty_2016 p
    ON p.county_fips = t.county_fips
  WHERE t.birth_year = 2017
    AND t.births_tot > 0
),
analytic_2018 AS (
  SELECT
    p.pov_rate_2017        AS poverty_rate,
    SAFE_DIVIDE(n.births_no_morb , t.births_tot) AS pct_no_morb
  FROM births_tot t
  JOIN births_no_morb n
    USING (birth_year, county_fips)
  JOIN poverty_2017 p
    ON p.county_fips = t.county_fips
  WHERE t.birth_year = 2018
    AND t.births_tot > 0
)
/* ---------- compute Pearson correlations ---------- */
SELECT 2016 AS birth_year, CORR(poverty_rate, pct_no_morb) AS pearson_corr
FROM analytic_2016

UNION ALL
SELECT 2017 AS birth_year, CORR(poverty_rate, pct_no_morb) AS pearson_corr
FROM analytic_2017

UNION ALL
SELECT 2018 AS birth_year, CORR(poverty_rate, pct_no_morb) AS pearson_corr
FROM analytic_2018
ORDER BY birth_year;