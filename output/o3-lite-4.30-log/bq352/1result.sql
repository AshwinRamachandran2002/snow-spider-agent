SELECT
  n.County_of_Residence                       AS county,
  ROUND(AVG(n.Ave_Number_of_Prenatal_Wks),4) AS average_prenatal_weeks_2018
FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS n
JOIN `bigquery-public-data.census_bureau_acs.county_2017_1yr`       AS a
  ON n.County_of_Residence_FIPS = a.geo_id
WHERE n.Year = DATE '2018-01-01'
  AND SUBSTR(n.County_of_Residence_FIPS,1,2) = '55'
  AND a.commute_45_59_mins / a.workers_16_and_over > 0.05
GROUP BY county
ORDER BY county;