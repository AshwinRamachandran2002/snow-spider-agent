SELECT
  f.`facility_sub_region_2` AS county_name,
  ROUND((COUNT(DISTINCT f.`facility_provider_id`) / c.`total_pop`) * 1000, 4) AS vaccine_sites_per_1000_people
FROM
  `bigquery-public-data.covid19_vaccination_access.facility_boundary_us_all` AS f
INNER JOIN
  `bigquery-public-data.census_bureau_acs.county_2018_5yr` AS c
ON
  f.`facility_sub_region_2_code` = c.`geo_id`
WHERE
  f.`facility_sub_region_1` = 'California'
GROUP BY
  county_name, c.`total_pop`
ORDER BY
  vaccine_sites_per_1000_people DESC