-- Vaccine sites per 1,000 residents for every California county
WITH population AS (
  -- 2018 5‑year ACS county‑level population
  SELECT
    geo_id                                   AS county_fips,         -- 5‑digit FIPS (state+county)
    total_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2018_5yr`
  WHERE LEFT(geo_id, 2) = '06'                                     -- California = FIPS state code 06
),
sites AS (
  -- Distinct vaccination facilities located in each California county
  SELECT
    facility_sub_region_2_code               AS county_fips,        -- 5‑digit county FIPS
    COUNT(DISTINCT facility_place_id)        AS site_count
  FROM `bigquery-public-data.covid19_vaccination_access.facility_boundary_us_all`
  WHERE facility_sub_region_1_code = 'US-CA'                       -- facilities in California
  GROUP BY county_fips
)
SELECT
  p.county_fips,
  p.total_pop,
  IFNULL(s.site_count, 0)                                           AS vaccine_sites,
  ROUND( IFNULL(s.site_count, 0) * 1000.0 / p.total_pop , 4)        AS sites_per_1000_pop
FROM population p
LEFT JOIN sites s USING (county_fips)
ORDER BY sites_per_1000_pop DESC;