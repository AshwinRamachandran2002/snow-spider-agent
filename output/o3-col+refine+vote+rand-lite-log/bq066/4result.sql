/* --------------------------------------------------------------
   Relationship between county-level poverty (from the most recent
   prior 5-year ACS file available) and the percentage of births
   with NO maternal morbidity, for natality years 2016-2018.
-----------------------------------------------------------------*/
WITH
-- 1.  Natality data for 2016-2018
natality AS (
  SELECT
    EXTRACT(YEAR FROM Year)          AS birth_year,
    County_of_Residence_FIPS         AS county_fips,
    Maternal_Morbidity_YN,
    Births
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
),

-- 2.  County–year percentage of births with NO maternal morbidity
pct_no_morb AS (
  SELECT
    birth_year,
    county_fips,
    SAFE_DIVIDE(
      SUM(IF(Maternal_Morbidity_YN = 0, Births, 0)),
      SUM(Births)
    )                           AS pct_no_morbidity
  FROM natality
  GROUP BY birth_year, county_fips
),

-- 3.  Prior-year poverty rates
--     (2012-2016 ACS supports 2016 & 2017 births;
--      2014-2018 ACS supports 2018 births)
poverty_aligned AS (
  -- for 2016 births → use 2016_5yr ACS
  SELECT
    2016                           AS birth_year,
    geo_id                         AS county_fips,
    SAFE_DIVIDE(poverty,total_pop) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  UNION ALL
  -- for 2017 births → still use 2016_5yr ACS
  SELECT
    2017,
    geo_id,
    SAFE_DIVIDE(poverty,total_pop)
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  UNION ALL
  -- for 2018 births → use 2018_5yr ACS
  SELECT
    2018,
    geo_id,
    SAFE_DIVIDE(poverty,total_pop)
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
)

-- 4.  Pearson correlations by birth year
SELECT
  birth_year,
  CORR(poverty_rate, pct_no_morbidity) AS pearson_corr
FROM pct_no_morb
JOIN poverty_aligned USING (birth_year, county_fips)
GROUP BY birth_year
ORDER BY birth_year;