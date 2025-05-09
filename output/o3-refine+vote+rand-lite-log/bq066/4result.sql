-- poverty vs. % births with NO maternal morbidity
WITH
-- total births per county & year
total_births AS (
  SELECT
    EXTRACT(YEAR FROM Year)            AS birth_year,
    County_of_Residence_FIPS           AS county_fips,
    SUM(Births)                        AS births_all
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
  WHERE EXTRACT(YEAR FROM Year) IN (2016, 2017, 2018)
  GROUP BY birth_year, county_fips
),
-- births where mothers had NO reported morbidity
no_morbidity_births AS (
  SELECT
    EXTRACT(YEAR FROM Year)            AS birth_year,
    County_of_Residence_FIPS           AS county_fips,
    SUM(Births)                        AS births_no_morb
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE Maternal_Morbidity_Desc = 'None checked'
    AND EXTRACT(YEAR FROM Year) IN (2016, 2017, 2018)
  GROUP BY birth_year, county_fips
),
-- percentage of births w/ no morbidity
birth_pct AS (
  SELECT
    t.birth_year,
    t.county_fips,
    n.births_no_morb / t.births_all AS pct_no_morbidity
  FROM total_births t
  JOIN no_morbidity_births n
  USING (birth_year, county_fips)
  WHERE t.births_all > 0
),
-- poverty rate from prior‑year 5‑year ACS
acs AS (
  SELECT 2016 AS birth_year, geo_id AS county_fips,
         poverty / total_pop AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  UNION ALL
  SELECT 2017, geo_id, poverty / total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  UNION ALL
  SELECT 2018, geo_id, poverty / total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),
-- join births & poverty
joined AS (
  SELECT
    b.birth_year,
    b.county_fips,
    b.pct_no_morbidity,
    a.poverty_rate
  FROM birth_pct b
  JOIN acs a
    ON a.birth_year = b.birth_year
   AND a.county_fips = b.county_fips
  WHERE a.poverty_rate IS NOT NULL
    AND b.pct_no_morbidity IS NOT NULL
),
-- Pearson correlation by year
correlations AS (
  SELECT
    birth_year                              AS year,
    CORR(poverty_rate, pct_no_morbidity)    AS pearson_corr
  FROM joined
  GROUP BY year
)
SELECT *
FROM correlations
ORDER BY year;