-- Task: List the average number of prenatal weeks in 2018 for counties in Wisconsin.

SELECT
  n.County_of_Residence AS County_Name,
  ROUND(AVG(n.Ave_Number_of_Prenatal_Wks), 4) AS Ave_Number_of_Prenatal_Wks
FROM
  `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS n
WHERE
  n.Year = DATE '2018-01-01'
  AND SUBSTR(n.County_of_Residence_FIPS, 1, 2) = '55'  -- Wisconsin State FIPS code is '55'
GROUP BY
  n.County_of_Residence