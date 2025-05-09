-- Relationship between prior-year county poverty rate (ACS 5-year) 
-- and percentage of births WITHOUT maternal morbidity, 2016-2018
WITH natal AS (
  SELECT
    EXTRACT(YEAR FROM Year)            AS birth_year,
    County_of_Residence_FIPS           AS geo_id,
    SAFE_DIVIDE(
      SUM(CASE WHEN Maternal_Morbidity_YN = 0 THEN Births ELSE 0 END),
      SUM(Births)
    )                                  AS pct_no_morbidity
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE Year IN ('2016-01-01','2017-01-01','2018-01-01')
  GROUP BY birth_year, geo_id
),
acs AS (
  -- poverty rate for 2015 (used with 2016 births)
  SELECT 2016 AS birth_year,
         geo_id,
         SAFE_DIVIDE(poverty, total_pop) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  UNION ALL
  -- poverty rate for 2016 (used with 2017 births)
  SELECT 2017,
         geo_id,
         SAFE_DIVIDE(poverty, total_pop)
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  UNION ALL
  -- poverty rate for 2017 (used with 2018 births)
  SELECT 2018,
         geo_id,
         SAFE_DIVIDE(poverty, total_pop)
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
)
SELECT
  birth_year,
  CORR(poverty_rate, pct_no_morbidity) AS pearson_corr
FROM acs
JOIN natal USING (birth_year, geo_id)
GROUP BY birth_year
ORDER BY birth_year;