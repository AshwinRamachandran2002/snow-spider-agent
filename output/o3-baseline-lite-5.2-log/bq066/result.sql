-- correlation between county poverty rate (from prior‑year ACS 5‑yr files)
-- and share of births with NO reported maternal morbidity
WITH county_poverty AS (
  -- poverty rate = persons in poverty / persons with determined poverty status
  SELECT
    2016            AS birth_year,
    LPAD(geo_id,5,'0') AS county_fips,
    SAFE_DIVIDE(poverty , pop_determined_poverty_status) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  WHERE pop_determined_poverty_status > 0

  UNION ALL
  SELECT
    2017,
    LPAD(geo_id,5,'0'),
    SAFE_DIVIDE(poverty , pop_determined_poverty_status)
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  WHERE pop_determined_poverty_status > 0

  UNION ALL
  SELECT
    2018,
    LPAD(geo_id,5,'0'),
    SAFE_DIVIDE(poverty , pop_determined_poverty_status)
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
  WHERE pop_determined_poverty_status > 0
),
births_no_morb AS (
  -- births where NO maternal morbidity was reported
  SELECT
    EXTRACT(YEAR FROM Year)                     AS birth_year,
    LPAD(County_of_Residence_FIPS,5,'0')        AS county_fips,
    SUM(Births)                                 AS births_no_morb
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE Maternal_Morbidity_YN = 1
    AND EXTRACT(YEAR FROM Year) IN (2016,2017,2018)
  GROUP BY birth_year, county_fips
),
births_total AS (
  SELECT
    EXTRACT(YEAR FROM Year)                     AS birth_year,
    LPAD(County_of_Residence_FIPS,5,'0')        AS county_fips,
    SUM(Births)                                 AS total_births
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
  WHERE EXTRACT(YEAR FROM Year) IN (2016,2017,2018)
  GROUP BY birth_year, county_fips
),
county_metrics AS (
  SELECT
    b.birth_year,
    b.county_fips,
    SAFE_DIVIDE(n.births_no_morb , b.total_births) AS pct_no_morbidity,
    p.poverty_rate
  FROM births_total b
  JOIN births_no_morb n
    ON n.birth_year = b.birth_year
   AND n.county_fips = b.county_fips
  JOIN county_poverty p
    ON p.birth_year = b.birth_year
   AND p.county_fips = b.county_fips
  WHERE b.total_births > 0
)
SELECT
  birth_year,
  CORR(pct_no_morbidity , poverty_rate) AS pearson_correlation
FROM county_metrics
GROUP BY birth_year
ORDER BY birth_year;