WITH acs AS (
  -- Poverty rate from the ACS 5‑year file for the year prior to the birth year
  SELECT '2016' AS birth_year,
         geo_id AS fips,
         poverty / pop_determined_poverty_status AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  WHERE pop_determined_poverty_status > 0
  
  UNION ALL
  
  SELECT '2017' AS birth_year,
         geo_id AS fips,
         poverty / pop_determined_poverty_status AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  WHERE pop_determined_poverty_status > 0
  
  UNION ALL
  
  SELECT '2018' AS birth_year,
         geo_id AS fips,
         poverty / pop_determined_poverty_status AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
  WHERE pop_determined_poverty_status > 0
),
births AS (
  -- Percentage of births with NO reported maternal morbidity
  SELECT CAST(EXTRACT(YEAR FROM Year) AS STRING) AS birth_year,
         County_of_Residence_FIPS                  AS fips,
         SUM(
           CASE
             WHEN Maternal_Morbidity_Desc = 'None checked' OR Maternal_Morbidity_YN = 1
             THEN Births
             ELSE 0
           END
         ) / SUM(Births)                           AS pct_no_morbidity
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
  GROUP BY birth_year, fips
)
SELECT
  birth_year AS year,
  ROUND(CORR(poverty_rate, pct_no_morbidity), 4) AS poverty_vs_no_morbidity_pearson_r
FROM acs
JOIN births USING (birth_year, fips)
GROUP BY year
ORDER BY year;