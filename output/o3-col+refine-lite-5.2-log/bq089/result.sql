-- Vaccine sites per 1,000 residents for every California county
WITH population AS (
  SELECT
    geo_id AS county_fips,          -- 5‑digit FIPS
    total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
  WHERE geo_id LIKE '06%'           -- 06 = California
),
vax_sites AS (
  SELECT
    facility_sub_region_2_code AS county_fips,
    COUNT(DISTINCT facility_place_id) AS facility_sites
  FROM `bigquery-public-data.covid19_vaccination_access.facility_boundary_us_all`
  WHERE facility_sub_region_1 = 'California'
  GROUP BY county_fips
)
SELECT
  p.county_fips,
  p.total_pop,
  COALESCE(s.facility_sites, 0)              AS facility_sites,
  ROUND( COALESCE(s.facility_sites, 0) / p.total_pop * 1000 , 4)
         AS sites_per_1000
FROM population AS p
LEFT JOIN vax_sites AS s
USING (county_fips)
ORDER BY sites_per_1000 DESC;