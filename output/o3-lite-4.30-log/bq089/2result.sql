SELECT
  p.county,
  ROUND(IFNULL(s.site_count, 0) * 1000 / p.total_pop, 4) AS sites_per_1000
FROM (
  SELECT
    geo_id AS county,
    total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
  WHERE geo_id LIKE '06%'          -- California counties
) AS p
LEFT JOIN (
  SELECT
    facility_sub_region_2_code AS county,
    COUNT(DISTINCT facility_place_id) AS site_count
  FROM `bigquery-public-data.covid19_vaccination_access.facility_boundary_us_all`
  WHERE facility_sub_region_1 = 'California'
  GROUP BY facility_sub_region_2_code
) AS s
USING (county)
ORDER BY county;