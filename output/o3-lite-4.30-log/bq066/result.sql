WITH poverty AS (
  -- poverty rate from prior‑year 5‑year ACS files
  SELECT '2016' AS year,
         LPAD(geo_id,5,'0') AS fips,
         SAFE_DIVIDE(poverty, pop_determined_poverty_status) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  UNION ALL
  SELECT '2017',
         LPAD(geo_id,5,'0'),
         SAFE_DIVIDE(poverty, pop_determined_poverty_status)
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  UNION ALL
  SELECT '2018',
         LPAD(geo_id,5,'0'),
         SAFE_DIVIDE(poverty, pop_determined_poverty_status)
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),
no_morbidity AS (
  -- percentage of births with NO maternal morbidity by county/year
  SELECT CAST(EXTRACT(YEAR FROM nm.Year) AS STRING) AS year,
         nm.County_of_Residence_FIPS                AS fips,
         SAFE_DIVIDE(SUM(nm.Births), MAX(tot.Births)) AS pct_no_morbidity
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity` AS nm
  JOIN `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS tot
    ON  nm.Year = tot.Year
   AND nm.County_of_Residence_FIPS = tot.County_of_Residence_FIPS
  WHERE nm.Maternal_Morbidity_YN = 1
    AND nm.Year IN ('2016-01-01','2017-01-01','2018-01-01')
  GROUP BY year, fips
)
SELECT
  year,
  ROUND(CORR(poverty_rate, pct_no_morbidity), 4) AS poverty_vs_no_morbidity_pearson_r
FROM poverty
JOIN no_morbidity USING (year, fips)
GROUP BY year
ORDER BY year;