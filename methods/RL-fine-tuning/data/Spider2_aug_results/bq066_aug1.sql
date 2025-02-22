-- Task: For the year 2016, calculate the poverty rate and the percentage of births without maternal morbidity for each county. Limit the results to 100 rows.

SELECT
  p.geo_id AS county_fips,
  (p.poverty / p.pop_determined_poverty_status) * 100 AS poverty_rate,
  (SUM(CASE WHEN n.Maternal_Morbidity_YN = 0 THEN n.Births ELSE 0 END) / SUM(n.Births)) * 100 AS percentage_without_morbidity
FROM
  `bigquery-public-data.census_bureau_acs.county_2015_5yr` p
JOIN
  `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity` n
ON
  p.geo_id = n.County_of_Residence_FIPS
WHERE
  p.pop_determined_poverty_status > 0
  AND EXTRACT(YEAR FROM n.Year) = 2016
GROUP BY
  p.geo_id, p.poverty, p.pop_determined_poverty_status
LIMIT 100