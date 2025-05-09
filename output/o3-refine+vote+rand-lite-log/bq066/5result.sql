WITH acs AS (
  -- poverty data from the 5‑year ACS released the year BEFORE the birth year
  SELECT '2016' AS birth_year,
         geo_id                               AS fips,
         SAFE_DIVIDE(poverty , NULLIF(total_pop,0)) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  UNION ALL
  SELECT '2017', geo_id,
         SAFE_DIVIDE(poverty , NULLIF(total_pop,0)) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  UNION ALL
  SELECT '2018', geo_id,
         SAFE_DIVIDE(poverty , NULLIF(total_pop,0)) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),
births AS (
  -- births where *no* maternal morbidity was reported
  SELECT
    CAST(EXTRACT(YEAR FROM Year) AS STRING)           AS birth_year,
    County_of_Residence_FIPS                          AS fips,
    SUM(CASE WHEN Maternal_Morbidity_YN = 1 THEN Births ELSE 0 END) AS births_no_morb,
    SUM(Births)                                       AS births_total
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
  GROUP BY birth_year, fips
),
birth_rates AS (
  SELECT
    birth_year,
    fips,
    SAFE_DIVIDE(births_no_morb, births_total) AS pct_no_morbidity
  FROM births
  WHERE births_total > 0
),
joined AS (
  SELECT
    b.birth_year,
    b.fips,
    a.poverty_rate,
    b.pct_no_morbidity
  FROM birth_rates b
  JOIN acs a
  ON  a.birth_year = b.birth_year
  AND a.fips       = b.fips
  WHERE a.poverty_rate IS NOT NULL
    AND b.pct_no_morbidity IS NOT NULL
)
SELECT
  birth_year,
  CORR(poverty_rate, pct_no_morbidity) AS pearson_correlation
FROM joined
GROUP BY birth_year
ORDER BY birth_year;