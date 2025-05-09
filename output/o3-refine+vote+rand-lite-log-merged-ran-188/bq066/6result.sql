-- Pearson correlation between prior–year county poverty rate and the share of
-- births with NO maternal morbidity, for birth years 2016-2018.
WITH births AS (
  SELECT
    EXTRACT(YEAR FROM `Year`)           AS birth_year,
    CAST(County_of_Residence_FIPS AS STRING) AS geo_id,
    SUM(CASE WHEN Maternal_Morbidity_YN = 1 THEN Births END) AS births_no_morbidity,
    SUM(Births)                                               AS births_total
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM `Year`) IN (2016, 2017, 2018)
  GROUP BY birth_year, geo_id
),
birth_rates AS (
  SELECT
    birth_year,
    geo_id,
    SAFE_DIVIDE(births_no_morbidity, births_total) AS pct_no_morbidity
  FROM births
),
poverty_raw AS (
  -- assemble the needed 5-year ACS county files (prior year to births)
  SELECT 2015 AS census_year, geo_id, poverty, total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  UNION ALL
  SELECT 2016, geo_id, poverty, total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  UNION ALL
  SELECT 2017, geo_id, poverty, total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),
poverty_rates AS (
  SELECT
    census_year,
    geo_id,
    SAFE_DIVIDE(poverty, total_pop) AS poverty_rate
  FROM poverty_raw
),
joined AS (
  SELECT
    b.birth_year,
    b.geo_id,
    b.pct_no_morbidity,
    p.poverty_rate
  FROM birth_rates b
  JOIN poverty_rates p
    ON p.geo_id = b.geo_id
   AND p.census_year = b.birth_year - 1
)
SELECT
  birth_year,
  CORR(poverty_rate, pct_no_morbidity) AS pearson_corr
FROM joined
GROUP BY birth_year
ORDER BY birth_year;