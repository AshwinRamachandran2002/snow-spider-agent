SELECT
  n.County_of_Residence AS County_Name,
  ROUND(AVG(n.Ave_Number_of_Prenatal_Wks), 4) AS Ave_Number_of_Prenatal_Wks
FROM
  `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS n
JOIN
  `bigquery-public-data.census_bureau_acs.county_2017_5yr` AS c
ON
  n.County_of_Residence_FIPS = c.geo_id
WHERE
  n.Year = DATE '2018-01-01'
  AND SUBSTR(c.geo_id, 1, 2) = '55'  -- Wisconsin State FIPS code is '55'
  AND c.employed_pop > 0
  AND c.commute_45_59_mins IS NOT NULL
  AND (c.commute_45_59_mins / c.employed_pop) > 0.05
GROUP BY
  n.County_of_Residence