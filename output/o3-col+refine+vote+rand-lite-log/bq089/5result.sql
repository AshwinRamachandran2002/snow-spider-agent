/* Vaccine-site availability (sites per 1,000 residents) for every
   California county, based on ACS-2018 5-year population estimates and the
   “all-modes” vaccination-facility layer                                */

WITH county_pop AS (               -- 2018 ACS population for CA counties
  SELECT
    geo_id,                        -- 5-digit county FIPS (e.g., 06037)
    total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
  WHERE geo_id LIKE '06%'          -- “06” prefix = California
),

county_name_xwalk AS (             -- map FIPS → county name used in site file
  SELECT
    CASE
      WHEN county_name = 'San Francisco' THEN 'San Francisco County'
      ELSE CONCAT(county_name, ' County')
    END                                                   AS county_name,
    CONCAT(LPAD(state_fips_code, 2, '0'),
           LPAD(county_fips_code, 3, '0'))                AS geo_id
  FROM `bigquery-public-data.geo_us_boundaries.counties`
  WHERE LPAD(state_fips_code, 2, '0') = '06'              -- California only
),

pop AS (                           -- population keyed by county_name
  SELECT
    n.county_name,
    p.total_pop
  FROM county_pop p
  JOIN county_name_xwalk n USING (geo_id)
),

site_counts AS (                   -- vaccination-site counts by county_name
  SELECT
    facility_sub_region_2 AS county_name,
    COUNT(*)               AS vaccine_sites
  FROM `bigquery-public-data.covid19_vaccination_access.facility_boundary_us_all`
  WHERE facility_sub_region_1 = 'California'
  GROUP BY county_name
)

SELECT
  pop.county_name,
  pop.total_pop,
  COALESCE(site_counts.vaccine_sites, 0)                                   AS vaccine_sites,
  ROUND(COALESCE(site_counts.vaccine_sites, 0) / pop.total_pop * 1000, 4)  AS vaccine_sites_per_1000_people
FROM pop
LEFT JOIN site_counts USING (county_name)
ORDER BY vaccine_sites_per_1000_people DESC;