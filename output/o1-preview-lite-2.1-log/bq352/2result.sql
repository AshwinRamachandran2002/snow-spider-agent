SELECT
  b.County_of_Residence AS County_Name,
  ROUND(b.Ave_Number_of_Prenatal_Wks, 4) AS Ave_Number_of_Prenatal_Wks
FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS b
JOIN `bigquery-public-data.census_bureau_acs.county_2017_5yr` AS a
  ON RIGHT(a.geo_id, 5) = b.County_of_Residence_FIPS
WHERE LEFT(b.County_of_Residence_FIPS, 2) = '55'  -- Wisconsin state FIPS code
  AND EXTRACT(YEAR FROM b.Year) = 2018
  AND a.employed_pop > 0
  AND SAFE_DIVIDE(a.commute_45_59_mins, a.employed_pop) > 0.05;