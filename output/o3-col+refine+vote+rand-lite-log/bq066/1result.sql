/*  Pearson correlation between the percentage of births with NO maternal
    morbidity and the prior-year 5-year ACS poverty rate
    (county-level, years 2016-2018)                                        */

WITH births_pct AS (
  SELECT
    EXTRACT(YEAR FROM `Year`)                 AS yr,
    CAST(County_of_Residence_FIPS AS INT64)   AS county_fips,
    SAFE_DIVIDE(
      SUM(CASE WHEN Maternal_Morbidity_YN = 1 THEN Births END),
      SUM(Births)
    )                                         AS no_mm_pct
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM `Year`) BETWEEN 2016 AND 2018
  GROUP BY yr, county_fips
),
poverty AS (
  -- 5-year ACS release one year prior to the birth year
  SELECT 2016 AS yr,
         CAST(geo_id AS INT64)                AS county_fips,
         SAFE_DIVIDE(poverty, total_pop)      AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  WHERE poverty IS NOT NULL AND total_pop IS NOT NULL

  UNION ALL
  SELECT 2017,
         CAST(geo_id AS INT64),
         SAFE_DIVIDE(poverty, total_pop)
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  WHERE poverty IS NOT NULL AND total_pop IS NOT NULL

  UNION ALL
  SELECT 2018,
         CAST(geo_id AS INT64),
         SAFE_DIVIDE(poverty, total_pop)
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
  WHERE poverty IS NOT NULL AND total_pop IS NOT NULL
)
SELECT
  yr,
  CORR(no_mm_pct, poverty_rate) AS pearson_corr
FROM births_pct
JOIN poverty USING (yr, county_fips)
GROUP BY yr
ORDER BY yr;